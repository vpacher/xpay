require 'test_helper'

class OperationTest < Test::Unit::TestCase
  context "an operation instance" do
    setup do
      @ops = Xpay::Operation.new(operation("class_test"))
      @request_xml = REXML::Document.new(Xpay.root_to_s)
    end
    should "have a auth_type" do
      assert_equal @ops.auth_type, "AUTH"
    end
    should "have a currency" do
      assert_equal @ops.currency, "USD"
    end
    should "have a amount=" do
      assert_equal @ops.amount, "1000"
    end
    should "have a settlement_day" do
      assert_equal @ops.settlement_day, "3"
    end
    should "have a callback_url" do
      assert_equal @ops.callback_url, "https://localhost/3dcallback"
    end
    should "have a site_reference" do
      assert_equal @ops.site_reference, "site56987"
    end
    should "have a site_alias" do
      assert_equal @ops.site_alias, "site56987"
    end
    should "have a merchant_name" do
      assert_equal @ops.merchant_name, "TestMerchant"
    end
    should "have a order_reference" do
      assert_equal @ops.order_reference, "TestOrder1245"
    end
    should "have a order_info" do
      assert_equal @ops.order_info, "TestOrderInfo"
    end
    should "create an xml document according to xpay spec" do
      @ops.add_to_xml(@request_xml)
      assert_equal(@request_xml.root.to_s, operation_xml_string)
      d {@request_xml.to_s}
    end

  end
end
