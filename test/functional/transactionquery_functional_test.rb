require 'test_helper'
require 'xpay'


class TransactionFunctionalTest < Test::Unit::TestCase

  context "a visa succesful no 3D payment" do
    setup do
      options = {:creditcard => Xpay::CreditCard.new(credit_card("visa_no3d_auth")), :operation => Xpay::Operation.new(operation("test_1")), :customer => Xpay::Customer.new(customer("test_1"))}
      @p = Xpay::Payment.new(options)
      Xpay.config.port = 5000
      @p.make_payment
      @tq = Xpay::TransactionQuery.new(:transaction_reference => @p.response_block[:transaction_reference], :site_reference => "testoutlet12092", :site_alias => "testoutlet12092")
      @tq.query
    end

    should "create a transaction query" do
      assert_instance_of Xpay::TransactionQuery, @tq
    end

    should "have a non empty response block" do
      assert !@tq.response_block.empty?
    end

  end

end