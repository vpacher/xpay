require 'test_helper'
require 'xpay'

class PaymentTest < Test::Unit::TestCase
  context "an empty payment instance" do
    setup do
      @p = Xpay::Payment.new()
    end

    should "have a the same xml as the module" do
      assert_equal @p.request_xml.root.to_s, Xpay.root_xml.root.to_s
    end

    should "have an response block with return nil" do
      assert @p.response_block.empty?
    end

    should "have an threesecure hash that has only emtpy elements" do
      assert @p.three_secure.empty?
    end
  end

  context "a payment instance from hashes" do
    setup do
      options = {:creditcard => credit_card("class_test"), :operation => operation("class_test"), :customer => customer("class_test")}
      @p = Xpay::Payment.new(options)
    end
    should "have a customer instance variable" do
      assert_instance_of(Xpay::Customer, @p.customer)
    end
    should "have a operations instance variable" do
      assert_instance_of(Xpay::Operation, @p.operation)
    end
    should "have a creditcard instance variable" do
      assert_instance_of(Xpay::CreditCard, @p.creditcard)
    end
  end
  context "a payment instance from class instance" do
    setup do
      options = {:creditcard => Xpay::CreditCard.new(credit_card("class_test")), :operation => Xpay::Operation.new(operation("class_test")), :customer => Xpay::Customer.new(customer("class_test"))}
      @p = Xpay::Payment.new(options)
    end
    should "have a customer instance variable" do
      assert_instance_of(Xpay::Customer, @p.customer)
    end
    should "have a operations instance variable" do
      assert_instance_of(Xpay::Operation, @p.operation)
    end
    should "have a creditcard instance variable" do
      assert_instance_of(Xpay::CreditCard, @p.creditcard)
    end
  end
end
