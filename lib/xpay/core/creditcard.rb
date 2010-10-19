module Xpay
  class CreditCard
    attr_accessor :type, :security_code, :valid_until, :valid_from, :security_code

    def number
      @number
    end
    def number=(new_val)
      @number = new_val.gsub(/[^0-9]/, "")
    end
  end
end