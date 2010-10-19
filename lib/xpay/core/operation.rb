module Xpay
  class Customer
    attr_accessor :currency, :settlement_day, :callback_url, :site_reference, :merchant_name, :http_accept, :user_agent,
                  :order_reference, :order_info

    def amount=(new_val)
      @amount = new_val.to_s
    end

    def amount
      @amount
    end
  end
end
