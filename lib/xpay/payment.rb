module Xpay

  # Payment Class handles all payment transaction AUTH, ST3DCARDQUERY and ST3DAUTH, also repeat transactions with ParentTransactionReference
  # instantiated with p = Xpay::Payment.new(options)
  # options is a Hash of the form keys creditcard, customer and operation
  # there are several different options:
  #
  # Option 1: pass as hash options = {:creditcard => {}, :customer => {}, :operation => {}}
  # in this case if the hash key is present and new CreditCard, Customer and Operation instance will be created from each hash and assigned to the class attributes
  #
  # Option 2: pass as Class instances of Xpay::CreditCard, Xpay::Customer and Xpay::Operation
  # simply assigns it to class attributes
  #
  # Option 3: create with emtpy hash and use attribute accessors
  # both as class and hash are possible
  #
  # It is not necessary to use the inbuilt classes Xpay::CreditCard, Xpay::Customer and Xpay::Operation,
  # you can use your own classes (for example if you have an active_record CreditCard class.
  # In this case your class(es) needs to implement a .add_to_xml method (best to copy the code from the gem classes)
  #
  # After initalization call the .make_payment method to process the payment
  # return codes are as follows:


  class Payment < Transaction
    attr_reader :creditcard, :customer, :operation

    def initialize(options={})
      @request_xml = REXML::Document.new(Xpay.root_to_s)
      options.each do |key, value|
        key=key.to_sym
      end
      self.creditcard = options[:creditcard] #.is_a?(Hash) ? Xpay::CreditCard.new(options[:creditcard]) : options[:creditcard]
      self.customer = options[:customer].is_a?(Hash) ? Xpay::Customer.new(options[:customer]) : options[:customer]
      self.operation = options[:operation].is_a?(Hash) ? Xpay::Operation.new(options[:operation]) : options[:operation]
      create_from_xml(options[:xml]) if options[:xml]
      create_request
    end

    def creditcard=(v)
      @creditcard = v.is_a?(Hash) ? Xpay::CreditCard.new(v) : v
    end

    def customer=(v)
      @customer = v.is_a?(Hash) ? Xpay::Customer.new(v) : v
    end

    def operation=(v)
      @operation = v.is_a?(Hash) ? Xpay::Operation.new(v) : v
    end

    def create_request
      self.creditcard.add_to_xml(@request_xml) if self.creditcard.respond_to?(:add_to_xml)
      self.customer.add_to_xml(@request_xml) if self.customer.respond_to?(:add_to_xml)
      self.operation.add_to_xml(@request_xml) if self.operation.respond_to?(:add_to_xml)
    end

    #TODO function to create classes (Customer, CreditCard and Operation) from xml request
    def create_from_xml(xml)

    end

    # the make_payment method is where all the action is happening
    # call it after you have initalized the Xpay::Payment class
    # the following returns are possible:
    #
    # -1 a 3D Secure Authorisation is required, query your payment instance e.g. p.three_secure
    # this will return a hash with all the necessary information to process the request further
    # TODO provide further documentation for three_secure response block
    #
    # 0 Error in processing settlement request
    # query your instance e.g. p.response_block for further information
    #
    # 1 Settlement request approved
    # query your instance e.g. p.response_block for further information
    #
    # 2 Settlement request declined
    # query your instance e.g. p.response_block for further information

    def make_payment
      @response_xml = self.process()
      if request_method=="ST3DCARDQUERY"
        # In case the request was a ST3DCARDQUERY (the default case) the further processing depends on the respones. If it was an AUTH request than all is done and the response_xml gets processed
        @response_xml = self.process() if response_code==0 # try once more if the response code is ZERO in ST3DCARDQUERY (According to securtrading tech support)
        case response_code
          when 1 # one means -> 3D AUTH required
            rewrite_request_block() # Rewrite the request block with information from the response, deleting unused items

            # If the card is enrolled in the scheme a redirect to a 3D Secure server is necessary, for this we need to store the request_xml in the database to be retrieved after the callback from the 3D secure Server and used to initialize a new payment object
            # otherwise, if the card is not enrolled we just do a 3D AUTH straight away
            if REXML::XPath.first(@response_xml, "//Enrolled").text == "Y"

              #card is enrolled, set @three_secure instance variable
              @three_secure = {:md => REXML::XPath.first(@response_xml, "//MD").text,
                               :pareq => REXML::XPath.first(@response_xml, "//PaReq").text,
                               :termurl => REXML::XPath.first(@response_xml, "//TermUrl").text,
                               :acsurl =>  REXML::XPath.first(@response_xml, "//AcsUrl").text,
                               :html =>  REXML::XPath.first(@response_xml, "//Html").text,
              }
              rt = -1
            else

              # The Card is not enrolled and we do a 3D Auth request without going through a 3D Secure Server
              # The PaRes element is required but empty as we did not go through a 3D Secure Server
              threedsecure = REXML::XPath.first(@request_xml, "//ThreeDSecure")
              pares = threedsecure.add_element("PaRes")
              pares.text = ""
              @response_xml = self.process()
              rt = REXML::XPath.first(@response_xml, "//Result").text.to_i
            end
          when 2 # TWO -> do a normal AUTH request
            rewrite_request_block("AUTH") # Rewrite the request block as AUTH request with information from the response, deleting unused items
            @response_xml = self.process()
            rt = REXML::XPath.first(@response_xml, "//Result").text.to_i
          else # ALL other cases, payment declined
            rt = REXML::XPath.first(@response_xml, "//Result").text.to_i
        end
      end
      return rt
    end

    def response_block
      @response_block ||= create_response_block
    end

    private

    def create_response_block
      rh = {:result_code => (REXML::XPath.first(@response_xml, "//Result").text.to_i rescue 0),
      }
      rh[:result_code] = REXML::XPath.first(@response_xml, "//Result").text.to_i rescue 0
      rh[:security_response_code] = REXML::XPath.first(@response_xml, "//SecurityResponseSecurityCode").text.to_i rescue nil
      rh[:security_response_postcode] = REXML::XPath.first(@response_xml, "//SecurityResponsePostCode").text.to_i rescue nil
      rh[:security_response_address] = REXML::XPath.first(@response_xml, "//SecurityResponseAddress").text.to_i rescue nil
      rh[:transaction_reference] = REXML::XPath.first(@response_xml, "//TransactionReference").text rescue nil
      rh[:transactionverifier] = REXML::XPath.first(@response_xml, "//TransactionVerifier").text rescue nil
      rh[:transaction_time] = REXML::XPath.first(@response_xml, "//TransactionCompletedTimestamp").text rescue nil
      rh[:auth_code] = REXML::XPath.first(@response_xml, "//AuthCode").text rescue nil
      rh[:settlement_status] = REXML::XPath.first(@response_xml, "//SettleStatus").text.to_i rescue nil
      rh[:error_code] = REXML::XPath.first(@response_xml, "//Message").text rescue nil
      return rh
    end
    # Method is called when it is a gateway callback, this is for future compatibility and easier code than writing additional logic to distinguish between normal auth and gateway callback auth
    def callback_process_payment
      @response_xml = Xpay.xpay(@request_xml)
    end

    # Rewrites the request according to the response coming from SecureTrading according to the required auth_type
    # This only applies if the inital request was a ST3DCARDQUERY
    # It deletes elements which are not needed for the subsequent request and
    # adds the required additional information if an ST3DAUTH is needed
    def rewrite_request_block(auth_type="ST3DAUTH")

      # set the required AUTH type
      REXML::XPath.first(@request_xml, "//Request").attributes["Type"] = auth_type

      # delete term url and merchant name
      op = REXML::XPath.first(@request_xml, "//Operation")
      op.delete_element "TermUrl"
      op.delete_element "MerchantName"

      # delete accept and user agent in customer info
      customer_info = REXML::XPath.first(@request_xml, "//CustomerInfo")
      customer_info.delete_element "//Accept"
      customer_info.delete_element "//UserAgent"

      # delete credit card details and add TransactionVerifier and TransactionReference from response xml
      # CC details are not needed anymore as verifier and reference are sufficient
      cc_details = REXML::XPath.first(@request_xml, "//CreditCard")
      cc_details.delete_element "//Number"
      cc_details.delete_element "//Type"
      trans_ver = cc_details.add_element("TransactionVerifier")
      trans_ver.text = REXML::XPath.first(@response_xml, "//TransactionVerifier").text
      trans_ref = cc_details.add_element("ParentTransactionReference")
      trans_ref.text = REXML::XPath.first(@response_xml, "//TransactionReference").text

      # unless it is an AUTH request, add additional required info for a 3DAUTH request
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
