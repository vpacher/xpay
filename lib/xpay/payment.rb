module Xpay
  class Payment < Transaction
    attr_accessor :credit_card, :customer, :operation

    def initialize(options={})
      @request_xml = REXML::Document.new(Xpay.root_to_s)
      self.credit_card = options["cc"].is_a?(Hash) ? Xpay::CreditCard.new(options["cc"]) : options["cc"]
      self.customer = options["cus"].is_a?(Hash) ? Xpay::Customer.new(options["cus"]) : options["cus"]
      self.operation = options["ops"].is_a?(Hash) ? Xpay::Operation.new(options["ops"]) : options["ops"]
      create_from_xml(options("xml")) if options("xml")
      create_request
    end

    def create_request
      self.credit_card.add_to_xml(@request_xml) if self.credit_card.respond_to?(:add_to_xml)
      self.customer.add_to_xml(@request_xml) if self.customer.respond_to?(:add_to_xml)
      self.operation.add_to_xml(@request_xml) if self.operation.respond_to?(:add_to_xml)
    end

    #TODO function to create classes (Customer, CreditCard and Operation) from xml request
    def create_from_xml(xml)

    end

    def make_payment
      @response_xml = self.process()
      if request_method=="ST3DCARDQUERY"
        # In case the request was a ST3DCARDQUERY (the default case) the further processing depends on the respones. If it was an AUTH request than all is done and the response_xml gets processed
        @response_xml = Xpay.xpay(@request_xml) if response_code==0 # try once more if the response code is ZERO in ST3DCARDQUERY (According to securtrading tech support)
        case response_code
          when 1 # one means -> 3D AUTH required
            rewrite_request_block # Rewrite the request block with information from the response, deleting unused items
            # If the card is enrolled in the scheme a redirect to a 3D Secure server is necessary, for this we need to store the request_xml in the database to be retrieved after the callback from the 3D secure Server and used to initialize a new payment object
            # otherwise, if the card is not enrolled we just do a 3D AUTH straight away
            if REXML::XPath.first(@response_xml, "//Enrolled").text == "Y"

              #card is enrolled, set @three_secure instance variable
              @three_secure = {:md => REXML::XPath.first(@response_xml, "//MD").text, :pareq => REXML::XPath.first(@response_xml, "//PaReq").text, :termurl => REXML::XPath.first(@response_xml, "//TermUrl").text, :acsurl =>  REXML::XPath.first(@response_xml, "//AcsUrl").text}

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

      end
    end
  end

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