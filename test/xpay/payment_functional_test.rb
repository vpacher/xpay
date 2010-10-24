require 'test_helper'
require 'xpay'

class PaymentFunctionTest < Test::Unit::TestCase
  context "an visa succesful no 3D payment" do
    setup do
      options = {:creditcard => Xpay::CreditCard.new(credit_card("visa_no3d_auth")), :operation => Xpay::Operation.new(operation("test_1")), :customer => Xpay::Customer.new(customer("test_1"))}
      @p = Xpay::Payment.new(options)
      Xpay.config.port = 5000
    end
    should "return 1 on make_payment" do
      rt = @p.make_payment
      d { @p.response_xml.to_s }
      assert_equal rt, 1
    end
  end
  context "an visa unsuccesful no 3D payment" do
    setup do
      options = {:creditcard => Xpay::CreditCard.new(credit_card("visa_no3d_decl")), :operation => Xpay::Operation.new(operation("test_1")), :customer => Xpay::Customer.new(customer("test_1"))}
      @p2 = Xpay::Payment.new(options)
      Xpay.config.port = 5000
    end
    should "return 0 on make_payment" do
      rt = @p2.make_payment
      d { @p2.response_xml.to_s }
      d { @p2.response_code }
      assert_equal 2, rt
    end
  end
  context "a mastercard succesful no 3D payment" do
    setup do
      options = {:creditcard => Xpay::CreditCard.new(credit_card("master_no3d_auth")), :operation => Xpay::Operation.new(operation("test_1")), :customer => Xpay::Customer.new(customer("test_1"))}
      @p = Xpay::Payment.new(options)
      Xpay.config.port = 5000
    end
    should "return 1 on make_payment" do
      rt = @p.make_payment
      d { @p.response_xml.to_s }
      assert_equal rt, 1
    end
  end

  context "an mastercard unsuccesful no 3D payment" do
    setup do
      options = {:creditcard => Xpay::CreditCard.new(credit_card("master_no3d_decl")), :operation => Xpay::Operation.new(operation("test_1")), :customer => Xpay::Customer.new(customer("test_1"))}
      @p2 = Xpay::Payment.new(options)
      Xpay.config.port = 5000
    end
    should "return 0 on make_payment" do
      rt = @p2.make_payment
      d { @p2.response_xml.to_s }
      d { @p2.response_code }
      assert_equal 2, rt
    end
  end
end