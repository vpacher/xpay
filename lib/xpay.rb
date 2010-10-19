require 'rexml/document'
include REXML

require 'xpay/configuration'
require 'xpay/transaction'
require 'xpay/payment'

module Xpay
  @xpay_config = {}
  @xpay_xml = {}
  class << self
    def load_configuration(xpay_config, xml_template = "#{RAILS_ROOT}/config/xpay.xml")
      if File.exist?(xpay_config)
        if defined? RAILS_ENV
          config = YAML.load_file(xpay_config)[RAILS_ENV]
        else
          config = YAML.load_file(xpay_config)
        end
        apply_configuration(config)
        read_xml(xml_template)
      end
    end
    def apply_configuration(config)
      @xpay_config = config
    end
    def read_xml(xml_template)
      f = File.read(xml_template)
      @xpay_xml = REXML::Document.new f
      op = @xpay_xml.root.elements["Request"].elements["Operation"]
      op.elements["SiteReference"].text = @xpay_config['merchant_reference']
      op.elements["MerchantName"].text = @xpay_config['merchant_name']
    end
    def config
      @xpay_config
    end
    def pxml
      @xpay_xml
    end
    

    # Test data for a successful none 3DSecure transaction
    def test_data
      cc = {:type => "Visa", :number => "4111111111111111", :securitycode => "123", :expirydate => "05/10"}
      operation = {:amount => 1000, :currency => "USD", :termurl => "http://localhost/gateway_callback"}
      customer = {:firstname => "Joe", :lastname => "Bloggs"}
      return {:operation => operation, :customer => customer, :creditcard => cc}
    end
    private
    def add_certificate(doc)
      cer = doc.root.add_element("Certificate")
      cer.text = load_certificate
      return doc
    end
    def load_certificate
      mycert = ''
      File.open(@xpay_config['path_to_cert'], "r") { |f| mycert = f.read}
      mycert.chomp
    end
  end
  class Payment_old
    @request_xml = REXML::Document # Request XML document, copied as instance variable from Xpay template on Class init
    @response_xml = REXML::Document # Response XML document, received from secure trading
    @three_secure = {} # 3D Secure information hash, used for redirecting to 3D Secure server in form
    def initialize(options={})
      # if the options contain an xpaytransaction object we use this for the init (in case of 3D Secure callback)
      unless options[:three_secure].blank?

        # 3D Secure call back happens as a POST, assign the params transmitted to the instance variable
        @three_secure = options[:three_secure]
        if xt = Xpay::XpayTransaction.find_by_md(@three_secure[:MD])
          # Delete the transaction straight away to avoid problems with browser refresh, maybe worthwile to explore modifying the record and lock it instead
          PendingTraXpay::XpayTransaction.delete(xt)

          # Assign the xml stored in the table to the instance variable
          @request_xml = xt.request_block

          # Add the PaRes element and add data as supplied by callback from 3D Secure Server (as post with params)
          threedsecure = REXML::XPath.first(@request_xml, "//ThreeDSecure")
          pares = threedsecure.add_element("PaRes")
          pares.text = @three_secure[:pares]

          # Process the payment
          callback_process_payment
        else
          # TODO add some error code here if the stored transaction can not be found (browser refresh, hacking attempt etc)
        end
        # Otherwise init a new payment with the data provided
      else
        # First we create an instance variable and copy the xml template that was initialized with xpay.yml into it.
        @request_xml = Xpay.pxml

        # Setting the desired request type depending on data provided, defaults to ST3DCARDQUERY if credit card is given or AUTH if transaction verifier is given (implies repeat transaction)
        unless options[:operation][:auth_type].blank?
          REXML::XPath.first(@request_xml, "//Request").attributes["Type"] = options[:operation][:auth_type]
        else
          auth_type = options[:creditcard][:transaction_verifier].blank? ? "ST3DCARDQUERY" : "AUTH"
          REXML::XPath.first(@request_xml, "//Request").attributes["Type"] = auth_type
        end

        # Fill it with all the data provided
        set_creditcard(options[:creditcard])
        set_customer(options[:customer])
        set_operation(options[:operation])
        #set_optional(options[:optional])
        # Process the Payment
        process_payment()
      end
      return response_block
    end
    def three_secure
      @three_secure
    end
    def response_block
      rh = {}
      rh[:result_code] = REXML::XPath.first(@response_xml, "//Result").text.to_i
      rh[:security_code_response] = REXML::XPath.first(@response_xml, "//SecurityResponseSecurityCode").text.to_i rescue nil
      rh[:transaction_reference] = REXML::XPath.first(@response_xml, "//TransactionReference").text rescue nil
      rh[:transaction_time] = REXML::XPath.first(@response_xml, "//TransactionCompletedTimestamp").text rescue nil
      rh[:auth_code] = REXML::XPath.first(@response_xml, "//AuthCode").text rescue nil
      rh[:settlement_status] = REXML::XPath.first(@response_xml, "//SettleStatus").text.to_i rescue nil
      return rh
    end
    def request_method
      REXML::XPath.first(@request_xml, "//Request").attributes["Type"]
    end
    def response_code
      REXML::XPath.first(@response_xml, "//Result").text.to_i
    end
    private
    
    def process_payment
      # Send it to Xpay
      @response_xml = Xpay.xpay(@request_xml)
      # Now take the response appart and see what we got
      case request_method
      when "ST3DCARDQUERY"
        # We did a 3D Card query, further action is now based on response code
        @response_xml = Xpay.xpay(@request_xml) if response_code==0 #if the response code is ZERO in ST3DCARDQUERY we try again one more time (According to securtrading tech support)
        case response_code
        when 1 # ONE -> 3D AUTH required
          rewrite_request_block # Rewrite the request block with information from the response, deleting unused items

          # If the card is enrolled in the scheme a redirect to a 3D Secure server is necessary, for this we need to store the request_xml in the database to be retrieved after the callback from the 3D secure Server and used to initialize a new payment object
          # otherwise, if the card is not enrolled we just do a 3D AUTH straight away
          if REXML::XPath.first(@response_xml, "//Enrolled").text == "Y"

            #card is enrolled, set @three_secure instance variable
            @three_secure = {:md => REXML::XPath.first(@response_xml, "//MD").text, :pareq => REXML::XPath.first(@response_xml, "//PaReq").text, :termurl => REXML::XPath.first(@response_xml, "//TermUrl").text, :acsurl =>  REXML::XPath.first(@response_xml, "//AcsUrl").text}

            #create XpayTransaction object to be recalled after gateway callback, identified by md
            xt = Xpay::XpayTransaction.create(:md => @three_secure[:md], :request_block => @request_xml)

          else

            # The Card is not enrolled and we do a 3D Auth request without going through a 3D Secure Server
            # The PaRes element is required but empty as we did not go through a 3D Secure Server
            threedsecure = REXML::XPath.first(@request_xml, "//ThreeDSecure")
            pares = threedsecure.add_element("PaRes")
            pares.text = ""
            @response_xml = Xpay.xpay(@request_xml)

          end
        when 2 # TWO -> do a normal AUTH request
          rewrite_request_block("AUTH") # Rewrite the request block as AUTH request with information from the response, deleting unused items
          @response_xml = Xpay.xpay(@request_xml)
        else # ALL other cases, payment declined
          # TODO add some result structure as hash to give access to response information in hash format
        end
      when "AUTH" #standard AUTH request, recurring payments with transaction verifier usually
        @response_xml = Xpay.xpay(@request_xml)
      end
    end

    # Method is called when it is a gateway callback, this is for future compatibility and easier code than writing additional logic to distinguish between normal auth and gateway callback auth
    def callback_process_payment
      @response_xml = Xpay.xpay(@request_xml)
    end
    #rewrites the request xml after a ST3DCARDQUERY according to the response code
    def rewrite_request_block(auth_type="ST3DAUTH")
      
      REXML::XPath.first(@request_xml, "//Request").attributes["Type"] = auth_type #sets the required auth type

      # delete term url and merchant name
      op = REXML::XPath.first(@request_xml, "//Operation")
      op.delete_element "TermUrl"
      op.delete_element "MerchantName"

      #delete accept and user agent in customer info
      customer_info = REXML::XPath.first(@request_xml, "//CustomerInfo")
      customer_info.delete_element "//Accept"
      customer_info.delete_element "//UserAgent"

      #delete credit card details and add TransactionVerifier and TransactionReference from response xml
      cc_details = REXML::XPath.first(@request_xml, "//CreditCard")
      cc_details.delete_element "//Number"
      cc_details.delete_element "//Type"
      trans_ver = cc_details.add_element("TransactionVerifier")
      trans_ver.text = REXML::XPath.first(@response_xml, "//TransactionVerifier").text
      trans_ref = cc_details.add_element("ParentTransactionReference")
      trans_ref.text = REXML::XPath.first(@response_xml, "//TransactionReference").text

      #unless it is an AUTH request, add additional required info for 3DAUTH
      unless auth_type == "AUTH"
        pm_method = REXML::XPath.first(@request_xml, "//PaymentMethod")
        threedsecure = pm_method.add_element("ThreeDSecure")
        enrolled = threedsecure.add_element("Enrolled")
        enrolled.text = REXML::XPath.first(@response_xml, "//Enrolled").text
        md = threedsecure.add_element("MD")
        md.text = REXML::XPath.first(@response_xml, "//MD").text rescue ""
      end

    end

    # Set the credit card block in the XML document
    def set_creditcard(block)

      cc = @request_xml.root.elements["Request"].elements["PaymentMethod"].elements["CreditCard"]
      # If a transaction verifier is present a repeat transaction is implied otherwise we fill in the Credit Card data
      if block[:transaction_verifier].blank?
        cc.elements["Type"].text = block[:type]
        cc.elements["Number"].text = block[:number]
        block[:issue].blank? ? cc.delete_element("Issue") : cc.elements["Issue"].text = block[:issue]
        block[:startdate].blank? ? cc.delete_element("StartDate") : cc.elements["StartDate"].text = block[:startdate]
        cc.elements["SecurityCode"].text = block[:securitycode]
        cc.elements["ExpiryDate"].text = block[:expirydate]
      else
        cc.delete_element("Type")
        cc.delete_element("Number")
        cc.delete_element("Issue")
        cc.delete_element("StartDate")
        cc.delete_element("SecurityCode")
        cc.delete_element("SecurityCode")
        tv = cc.add_element("TransactionVerifier")
        tv.text = block[:transaction_verifier]
        ptr = cc.add_element("ParentTransactionReference")
        ptr.text = block[:parent_transaction_reference]
      end
    end
    def set_customer(block)
      # Root element for all customer info
      cus = @request_xml.root.elements["Request"].elements["CustomerInfo"]

      # User agent and Accept encoding goes here
      unless (block[:user_agent].blank? || block[:accept].blank?) #both elements are required for 3D Secure, if missing AUTH is assumed and both elements are removed from the xml
        cus.elements["UserAgent"].text = block[:user_agent]
        cus.elements["Accept"].text = block[:accept]
      else
        cus.delete_element("//UserAgent")
        cus.delete_element("//Accept")
      end

      # Postal node -> name and adress
      postal = cus.elements["Postal"]

      # Customer Name
      name = postal.elements["Name"]
      block[:nameprefix].blank? ? name.delete_element("NamePrefix") : name.elements["NamePrefix"].text = block[:nameprefix]
      name.elements["FirstName"].text = block[:firstname]
      block[:middlename].blank? ? name.delete_element("MiddleName") : name.elements["MiddleName"].text = block[:middlename]
      name.elements["LastName"].text = block[:lastname]
      block[:namesuffix].blank? ? name.delete_element("NameSuffix") : name.elements["NameSuffix"].text = block[:namesuffix]
      
      # Address and Company name
      block[:company_name].blank? ? postal.delete_element("Company") : postal.elements["Company"].text = block[:company_name]
      block[:street].blank? ? postal.delete_element("Street") : postal.elements["Street"].text = block[:street]
      block[:city].blank? ? postal.delete_element("City") : postal.elements["City"].text = block[:city]
      block[:state].blank? ? postal.delete_element("StateProv") : postal.elements["StateProv"].text = block[:state]
      block[:zip].blank? ? postal.delete_element("PostalCode") : postal.elements["PostalCode"].text = block[:zip]
      block[:country_code].blank? ? postal.delete_element("CountryCode") : postal.elements["CountryCode"].text = block[:country_code]

      # Telephone
      telco = cus.elements["Telecom"]
      block[:phone_number].blank? ? cus.delete_element("Telecom") : telco.elements["Phone"].text = block[:phone_number]

      #email
      online_info = cus.elements["Online"]
      block[:email].blank? ? cus.delete_element("Online") : online_info.elements["Email"].text = block[:email]
    end
    def set_operation(block)
      # Operation block root
      ops = @request_xml.root.elements["Request"].elements["Operation"]
      ops.elements["Amount"].text = block[:amount]
      ops.elements["Currency"].text = block[:currency] unless block[:currency].blank?
      ops.elements["SettlementDay"].text = block[:settlementday] unless block[:settlementday].blank?

      # Term Url is required for 3D Secure
      unless block[:termurl].blank? # Implies 3D Secure, if missing AUTH is implied and TermUrl and MerchantName are removed
        ops.elements["TermUrl"].text = block[:termurl]
      else
        ops.delete_element("TermUrl")
        ops.delete_element("MerchantName")
      end

      # Order information
      # this is a seperate block in the xml but for the sake of reduced complexity I've included it in the operation hash
      order_info = @request_xml.root.elements["Request"].elements["Order"]
      order_info.elements["OrderReference"].text = block[:order_ref]
      order_info.elements["OrderInformation"].text = block[:order_info]
    end
  end
end