require 'test_helper'

class CreditCardTest < Test::Unit::TestCase
  context "a creditcard instance" do
    setup do
      @cc = Xpay::CreditCard.new(credit_card("class_test"))
    end
    should "have a credit card type" do
      assert_equal @cc.card_type, "Visa"
    end
    should "have a partly hidden credit card number" do
      assert_equal @cc.number, "xxxxxxxxxxxx1111"
    end
    should "have an expiry date" do
      assert_equal @cc.valid_until, "0510"
    end
    should "have an start date" do
      assert_equal @cc.valid_from, "0110"
    end
    should "have an issue number" do
      assert_equal @cc.issue, "1"
    end
end
end
