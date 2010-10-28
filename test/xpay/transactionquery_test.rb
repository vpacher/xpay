require "test_helper"
require 'xpay'

class TransactionQueryTest < Test::Unit::TestCase

  context "an empty instance" do
    setup do
      @t = Xpay::TransactionQuery.new()
    end

    should "have attributes" do
      assert @t.respond_to? :transaction_reference
      assert @t.respond_to? :order_reference
      assert @t.respond_to? :site_reference
    end
  end
end