module Xpay
  class Payment < Transaction

    def initialize(options={})

    end

    def credit_card
      @credit_card
    end

    def credit_card=(new_cc)
      @credit_card = new_cc
    end
  end
end