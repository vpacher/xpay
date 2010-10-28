module Xpay

  class TransactionQuery < Transaction
    attr_accessor :transaction_reference, :order_reference, :site_reference

    def initialize(options={})
      options.each do |key, value|
        self.send("#{key}=", value) if self.respond_to? key
      end
    end
  end
end