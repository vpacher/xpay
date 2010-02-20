require 'rexml/document'
include REXML

module Xpay
  @xpay_config = {}
  @xpay_xml = {}
  class << self
    def load_configuration(xpay_config, xml_template = "#{RAILS_ROOT}/vendor/plugins/xpay/templates/xpay.xml")
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
    
    # Here the actual work happens, xml supplied is written to the socket, repsone block is returned
    def xpay(request_block)
      # adding the certificate as last step before writing it to the socket, this way it will not be stored by accident in the case of 3DAUTH
      r_block = add_certificate(request_block)

      # open the socket and write to it, wait for response, read it, close the port
      # TODO adding port as option to yaml file, investigate option of different host
      a = TCPSocket.open("localhost",5000)
      a.write(r_block.to_s)
      res = a.read()
      a.close

      # create an xml document, use everything from the start of <ResponseBlock to the end, discard header and status etc
      response_block = REXML::Document.new res[res.index("<ResponseBlock"), res.length]

      # Return the repsone block xml
      return response_block
    end

    # Test data for a succesfull none 3DSecure transaction
    def test_data
      cc = {:type => "Visa", :number => "4111111111111111", :securitycode => "123", :expirydate => "05/10"}
      operation = {:amount => 1000, :currency => "USD", :termurl => "http://localhost/gateway_callback"}
      customer = {:firstname => "Joe", :lastname => "Bloggs"}
      return {:operation => operation, :customer => customer, :creditcard => cc}
    end
    private
    def add_certificate(doc)
      cer = doc.root.add_element("Certificate")
      cer.text = Payment.load_certificate
      return doc
    end
    def load_certificate
      mycert = ''
      File.open(@xpay_config['path_to_cert'], "r") { |f| mycert = f.read}
      mycert.chomp
    end
  end
  class XpayTransaction < ActiveRecord::Base

  end
  class Payment
    @xml = REXML::Document
    @response_xml = REXML::Document
    def initialize(options={})
      # First we create an instance variable and copy the xml template that was initialized with xpay.yml into it.
      @xml = Xpay.pxml

      # Setting the desired request type depending on data provided, defaults to ST3DCARDQUERY if credit card is given or AUTH if transaction verifier is given (implies repeat transaction)
      unless options[:operation][:auth_type].blank?
        REXML::XPath.first(@xml, "//Request").attributes["Type"] = options[:operation][:auth_type]
      else
        auth_type = options[:creditcard][:transaction_verifier].blank? ? "ST3DCARDQUERY" : "AUTH"
        REXML::XPath.first(@xml, "//Request").attributes["Type"] = auth_type
      end

      # Fill it with all the data provided
      set_creditcard(options[:creditcard])
      set_customer(options[:customer])
      set_operation(options[:operation])
      #set_optional(options[:optional])
      # Process the Payment
      process_payment()
      
    end
    def operation
      Hash.from_xml(@xml.root.elements["Request"].elements["Operation"].to_s)
    end
    def xml
      @xml
    end

    private

    def process_payment
      # Send it to Xpay
      @response_xml = Xpay.xpay(@xml)
      # Now take the response appart and see what we got
      
    end
    def set_creditcard(block)

      cc = @xml.root.elements["Request"].elements["PaymentMethod"].elements["CreditCard"]
      # If a transaction verifier is present a repeat transaction is implied otherwise we fill in the Credit Card data
      unless block[:transaction_verifier].blank?
        cc.elements["Type"].text = block[:type]
        cc.elements["Number"].text = block[:number]
        block[:issue].blank? ? cc.delete_element["Issue"] : cc.elements["Issue"].text = block[:issue]
        block[:startdate].blank? ? cc.delete_element["StartDate"] : cc.elements["StartDate"].text = block[:startdate]
        cc.elements["SecurityCode"].text = block[:securitycode]
        cc.elements["ExpiryDate"].text = block[:expirydate]
      else
        cc.delete_element["Type"]
        cc.delete_element["Number"]
        cc.delete_element["Issue"]
        cc.delete_element["StartDate"]
        cc.delete_element["SecurityCode"]
        cc.delete_element["SecurityCode"]
        tv = cc.add_element("TransactionVerifier")
        tv.text = block[:transaction_verifier]
        ptr = cc.add_element("ParentTransactionReference")
        ptr.text = block[:parent_transaction_reference]
      end
    end
    def set_customer(block)
      # Root element for all customer info
      cus = @xml.root.elements["Request"].elements["CustomerInfo"]

      # User agent and Accept encoding goes here
      unless (block[:user_agent].blank? || block[:accept].blank?) #both elements are required for 3D Secure, if missing AUTH is assumed and both elements are removed from the xml
        cus.elements["UserAgent"].text = block[:user_agent]
        cus.elements["Accept"].text = block[:accept]
      else
        cus.delete_element("UserAgent")
        cus.delete_element("Accept")
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
      block[:company_name].blank? ? name.delete_element("Company") : name.elements["Company"].text = block[:company_name]
      block[:street].blank? ? name.delete_element("Street") : name.elements["Street"].text = block[:street]
      block[:city].blank? ? name.delete_element("City") : name.elements["City"].text = block[:city]
      block[:state].blank? ? name.delete_element("StateProv") : name.elements["StateProv"].text = block[:state]
      block[:zip].blank? ? name.delete_element("PostalCode") : name.elements["PostalCode"].text = block[:zip]
      block[:country_code].blank? ? name.delete_element("CountryCode") : name.elements["CountryCode"].text = block[:country_code]

      # Telephone
      telco = cus.elements["Telecom"]
      block[:phone_number].blank? ? telco.delete_element("Phone") : telco.elements["Phone"].text = block[:phone_number]

      #email
      online_info = cus.elements["Online"]
      block[:email].blank? ? online_info.delete_element("Email") : online_info.elements["Email"].text = block[:email]
    end
    def set_operation(block)
      # Operation block root
      ops = @xml.root.elements["Request"].elements["Operation"]
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
      order_info = @xml.root.elements["Request"].elements["Order"]
      order_info.elements["OrderReference"].text = block[:order_ref]
      order_info.elements["OrderInformation"].text = block[:order_info]
    end
  end
end