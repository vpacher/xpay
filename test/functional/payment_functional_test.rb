require 'test_helper'
require 'xpay'

class PaymentFunctionTest < Test::Unit::TestCase
  context "with rightly formed request" do
    context "a visa succesful no 3D payment" do
      setup do
        options = {:creditcard => Xpay::CreditCard.new(credit_card("visa_no3d_auth")), :operation => Xpay::Operation.new(operation("test_1")), :customer => Xpay::Customer.new(customer("test_1"))}
        @p = Xpay::Payment.new(options)
        Xpay.config.port = 5000
      end
      should "return 1 on make_payment" do
        rt = @p.make_payment
        assert_equal 1, rt
      end
    end

    context "a visa unsuccesful no 3D payment" do
      setup do
        options = {:creditcard => Xpay::CreditCard.new(credit_card("visa_no3d_decl")), :operation => Xpay::Operation.new(operation("test_1")), :customer => Xpay::Customer.new(customer("test_1"))}
        @p2 = Xpay::Payment.new(options)
        Xpay.config.port = 5000
      end
      should "return 0 on make_payment" do
        rt = @p2.make_payment
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
        assert_equal 1, rt
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
        assert_equal 2, rt
      end
    end

    context "an visa succesful 3D payment" do
      setup do
        options = {:creditcard => Xpay::CreditCard.new(credit_card("visa_3d_auth")), :operation => Xpay::Operation.new(operation("test_1")), :customer => Xpay::Customer.new(customer("test_1"))}
        @p = Xpay::Payment.new(options)
        Xpay.config.port = 5000
      end
      should "return -1 on make_payment" do
        rt = @p.make_payment
        assert_equal -1, rt
      end
    end
  end
  context "with wrongly formed request" do
    context "a visa with invalid datetime format" do
      setup do
        options = {:creditcard => Xpay::CreditCard.new(credit_card("visa_no3d_auth")), :operation => Xpay::Operation.new(operation("test_1")), :customer => Xpay::Customer.new(customer("test_1"))}
        options[:creditcard].valid_until = "0910"
        @p = Xpay::Payment.new(options)
        Xpay.config.port = 5000
        @rt = @p.make_payment
      end
      should "return 0 on make_payment" do
        assert_equal 0, @rt
      end
      should "return '(3100) Invalid ExpiryDate' in response block error code" do
        rt = @p.response_block[:error_code]
        assert_equal "(3100) Invalid ExpiryDate", rt
      end
    end
  end
end