require 'rexml/document'
require 'rexml/xmldecl'
require 'ostruct'
require 'erb'
require 'xpay/transaction'

module Xpay
  autoload :Payment, 'xpay/payment'
  autoload :CreditCard, 'xpay/core/creditcard'
  autoload :Customer, 'xpay/core/customer'
  autoload :Operation, 'xpay/core/operation'

  # These are the default settings. You can change them by placing YAML file into config/xpay.yml with settings for each environment.
  # Alternatively you can change the settings by calling the config setter for each attribute for example:
  # Xpay.config.alias = "your_new_alias"
  # Another option is to call Xpay.set_config with a hash containing the attributes you want to change
  #
  # merchant_name:  CompanyName
  # version:        3.51              'this is the only supported version at the moment and has to be 3.51, as String'
  # alias:          site12345
  # site_reference: site12345
  # port:           5000               'this needs to be an Integer'
  # default_query:  ST3DCARDQUERY      'defaults to 3D Card query if not otherwise specified'
  # settlement_day: 1                  'this needs to be a String'
  # default_currency: GBP

  @xpay_config = OpenStruct.new({
                                        "merchant_name" => "CompanyName",
                                        "version" => "3.51",
                                        "alias" => "site12345",
                                        "site_reference" => "site12345",
                                        "port" => 5000,
                                        "callback_url" => "http://localhost/gateway_callback",
                                        "default_query" => "ST3DCARDQUERY",
                                        "settlement_day" => "1",
                                        "default_currency" => "GBP"
                                })
  class << self
    attr_accessor :app_root, :environment

    def load_config(app_root = Dir.pwd)
      self.app_root = (RAILS_ROOT if defined?(RAILS_ROOT)) || app_root
      self.environment = (RAILS_ENV if defined?(RAILS_ENV)) || "development"
      parse_config
      return true
    end


    def root_xml
      @request_xml ||= create_root_xml
    end

    def root_to_s
      self.root_xml.to_s
    end

    def create_root_xml
      r = REXML::Document.new
      r << REXML::XMLDecl.new("1.0", "iso-8859-1")
      rb = r.add_element "RequestBlock", {"Version" => config.version}
      request = rb.add_element "Request", {"Type" => config.default_query}
      operation = request.add_element "Operation"
      site_ref = operation.add_element "SiteReference"
      site_ref.text = config.site_reference
      if config.version== "ST3DCARDQUERY"
        mn = operation.add_element "MerchanteName"
        mn.text = config.merchant_name
        tu = operation.add_element "TermUrl"
        tu.text = config.callback_url
      end
      cer = rb.add_element "Certificate"
      cer.text = config.alias
      return r
    end

    def config
      @xpay_config
    end

    def set_config(conf)
      conf.each do |key, value|
        @xpay_config.send("#{key}=", value) if @xpay_config.respond_to? key
      end
      return true
    end

    protected
    def parse_config
      path = "#{app_root}/config/xpay.yml"
      return unless File.exists?(path)
      conf = YAML::load(ERB.new(IO.read(path)).result)[environment]
      self.set_config(conf)
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
  end
end