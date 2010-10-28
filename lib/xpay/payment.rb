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
      self.creditcard = options[:creditcard] #.is_a?(Hash) ? Xpay::CreditCard.new(options[:creditcard]) : options[:creditcard]
      self.customer = options[:customer].is_a?(Hash) ? Xpay::Customer.new(options[:customer]) : options[:customer]
      self.operation = options[:operation].is_a?(Hash) ? Xpay::Operation.new(options[:operation]) : options[:operation]
      create_from_xml(options[:xml], options[:pares] || nil) if options[:xml]
      create_request
    end

    def creditcard=(v)
      @creditcard = v.is_a?(Hash) ? Xpay::CreditCard.new(v) : v
      create_request
    end

    def customer=(v)
      @customer = v.is_a?(Hash) ? Xpay::Customer.new(v) : v
      create_request
    end

    def operation=(v)
      @operation = v.is_a?(Hash) ? Xpay::Operation.new(v) : v
      create_request
    end

    # the make_payment method is where all the action is happening
    # call it after you have initalized the Xpay::Payment class
    # the following returns are possible:
    #
    # -1 a 3D Secure Authorisation is required, query your payment instance e.g. p.three_secure
    # this will return a hash with all the necessary information to process the request further
    # TODO provide further documentation for three_secure response block
    #
    # 0 Error in processing settlement request,
    # query your instance e.g. p.response_block for further information
    #
    # 1 Settlement request approved,
    # query your instance e.g. p.response_block for further information
    #
    # 2 Settlement request declined,
    # query your instance e.g. p.response_block for further information

    def make_payment
      @response_xml = process()
      if request_method=="ST3DCARDQUERY"
        # In case the request was a ST3DCARDQUERY (the default case) the further processing depends on the respones. If it was an AUTH request than all is done and the response_xml gets processed
        @response_xml = process() if response_code==0 # try once more if the response code is ZERO in ST3DCARDQUERY (According to securtrading tech support)
        case response_code
          when 1 # one means -> 3D AUTH required
            rewrite_request_block() # Rewrite the request block with information from the response, deleting unused items

            # If the card is enrolled in the scheme a redirect to a 3D Secure server is necessary, for this we need to store the request_xml in the database to be retrieved after the callback from the 3D secure Server and used to initialize a new payment object
            # otherwise, if the card is not enrolled we just do a 3D AUTH straight away
            if REXML::XPath.first(@response_xml, "//Enrolled").text == "Y"
              rt = -1
            else
              # The Card is not enrolled and we do a 3D Auth request without going through a 3D Secure Server
              # The PaRes element is required but empty as we did not go through a 3D Secure Server
              threedsecure = REXML::XPath.first(@request_xml, "//ThreeDSecure")
              pares = threedsecure.add_element("PaRes")
              pares.text = ""
              @response_xml = process()
              rt = response_code
            end
          when 2 # TWO -> do a normal AUTH request
            rewrite_request_block("AUTH") # Rewrite the request block as AUTH request with information from the response, deleting unused items
            @response_xml = process()
            rt = response_code
          else # ALL other cases, payment declined
            rt = response_code
        end
      else
        rt = response_code
      end
      rt
    end

    # The response_block is a hash and can have one of several values:
    # the follwing values are always present after a transaction and can be queried to gain further details of the transaction:
    #   * result_code:
    #       0 for failure, check error_code for further details
    #       1 transaction was succesful
    #       2 transaction was denied
    #   * security_response_code
    #   * security_response_postcode
    #   * transaction_reference
    #   * transactionverifier
    #   * transaction_time
    #   * auth_code
    #   * settlement_status
    #   * error_code
    def response_block
      create_response_block
    end

    def three_secure
      create_three_secure
    end

    private
    def create_request
      self.creditcard.add_to_xml(@request_xml) if self.creditcard.respond_to?(:add_to_xml)
      self.customer.add_to_xml(@request_xml) if self.customer.respond_to?(:add_to_xml)
      self.operation.add_to_xml(@request_xml) if self.operation.respond_to?(:add_to_xml)
    end

    #TODO function to create classes (Customer, CreditCard and Operation) from xml document
    def create_from_xml(xml, pares)
      raise PaResMissing.new "(2500) PaRes argument can not be omitted." if pares.nil?
      @request_xml = REXML::Document.new xml
      REXML::XPath.first(@request_xml, "//ThreeDSecure").add_element("PaRes").text=pares
    end

    def create_response_block
      @response_xml.is_a?(REXML::Document) ?
              {
                      :result_code => (REXML::XPath.first(@response_xml, "//Result").text.to_i rescue nil),
                      :security_response_code => (REXML::XPath.first(@response_xml, "//SecurityResponseSecurityCode").text.to_i rescue nil),
                      :security_response_postcode => (REXML::XPath.first(@response_xml, "//SecurityResponsePostCode").text.to_i rescue nil),
                      :security_response_address => (REXML::XPath.first(@response_xml, "//SecurityResponseAddress").text.to_i rescue nil),
                      :transaction_reference => (REXML::XPath.first(@response_xml, "//TransactionReference").text rescue nil),
                      :transactionverifier => (REXML::XPath.first(@response_xml, "//TransactionVerifier").text rescue nil),
                      :transaction_time => (REXML::XPath.first(@response_xml, "//TransactionCompletedTimestamp").text rescue nil),
                      :auth_code => (REXML::XPath.first(@response_xml, "//AuthCode").text rescue nil),
                      :settlement_status => (REXML::XPath.first(@response_xml, "//SettleStatus").text.to_i rescue nil),
                      :error_code => (REXML::XPath.first(@response_xml, "//Message").text rescue nil)
              } : {}
    end

    def create_three_secure
      @response_xml.is_a?(REXML::Document) ?
              {
                      :md => (REXML::XPath.first(@response_xml, "//MD").text rescue nil),
                      :pareq => (REXML::XPath.first(@response_xml, "//PaReq").text rescue nil),
                      :termurl => (REXML::XPath.first(@response_xml, "//TermUrl").text rescue nil),
                      :acsurl =>  (REXML::XPath.first(@response_xml, "//AcsUrl").text rescue nil),
                      :html =>  (REXML::XPath.first(@response_xml, "//Html").text rescue nil),
                      :request_xml => (@request_xml.to_s rescue nil)
              } : {}
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
      ["TermUrl", "MerchantName"].each { |e| op.delete_element e }

      # delete accept and user agent in customer info
      customer_info = REXML::XPath.first(@request_xml, "//CustomerInfo")
      ["Accept", "UserAgent"].each { |e| customer_info.delete_element e }

      # delete credit card details and add TransactionVerifier and TransactionReference from response xml
      # CC details are not needed anymore as verifier and reference are sufficient
      cc_details = REXML::XPath.first(@request_xml, "//CreditCard")
      ["Number", "Type", "SecurityCode", "StartDate", "ExpiryDate", "Issue"].each { |e| cc_details.delete_element e }
      cc_details.add_element("TransactionVerifier").text = REXML::XPath.first(@response_xml, "//TransactionVerifier").text
      cc_details.add_element("ParentTransactionReference").text = REXML::XPath.first(@response_xml, "//TransactionReference").text

      # unless it is an AUTH request, add additional required info for a 3DAUTH request
      unless auth_type == "AUTH"
        pm_method = REXML::XPath.first(@request_xml, "//PaymentMethod")
        threedsecure = pm_method.add_element("ThreeDSecure")
        threedsecure.add_element("Enrolled").text = REXML::XPath.first(@response_xml, "//Enrolled").text
        threedsecure.add_element("MD").text = REXML::XPath.first(@response_xml, "//MD").text rescue ""
      end
      true
    end
  end
end
