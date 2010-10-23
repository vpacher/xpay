module Xpay
  class CreditCard
    attr_accessor :card_type, :valid_until, :valid_from, :issue, :parent_transaction_ref, :transaction_verifier
    attr_writer :security_code
    def initialize(options={})
      if !options.nil? && options.is_a?(Hash)
        options.each do |key, value|
          self.send("#{key.to_s}=", value) if self.respond_to? key.to_s
        end
      end
    end

    def number
      @number.sub(/^([0-9]+)([0-9]{4})$/) { 'x' * $1.length + $2 }
    end

    def number=(new_val)
      @number = new_val.to_s.gsub(/[^0-9]/, "")
    end

    def security_code=(new_val)
      @security_code = new_val.to_s
    end

    def add_to_xml(doc)
      op = REXML::XPath.first(doc, "//Request")
      op.delete_element "PaymentMethod"
      pa = op.add_element "PaymentMethod"
      cc = pa.add_element("CreditCard")
      cc.add_element("Type").add_text(self.card_type) if self.card_type
      cc.add_element("Number").add_text(self.number_internal) if self.number_internal
      cc.add_element("StartDate").add_text(self.valid_from) if self.valid_from
      cc.add_element("ExpiryDate").add_text(self.valid_until) if self.valid_until
      cc.add_element("ParentTransactionReference").add_text(self.parent_transaction_ref) if self.parent_transaction_ref
      cc.add_element("TransactionVerifier").add_text(self.transaction_verifier) if self.transaction_verifier
      cc.add_element("SecurityCode").add_text(self.security_code) if self.security_code
      cc.add_element("Issue").add_text(self.issue) if self.issue
    end

    protected
    def number_internal
      @number
    end

    def security_code
      @security_code
    end
  end
end