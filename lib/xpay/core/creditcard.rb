module Xpay
  class CreditCard
    attr_accessor :type, :security_code, :valid_until, :valid_from, :issue, :security_code, :transaction_ref

    def number
      @number
    end
    def number=(new_val)
      @number = new_val.gsub(/[^0-9]/, "")
    end

    def add_to_xml(doc)
      op = REXML::XPath.first(doc, "//Request")
      op.delete_element "PaymentInfo"
      pi = op.add_element "PaymentInfo"

    end
  end
end