require "test_helper"
require 'xpay'

class TransactionQueryTest < Test::Unit::TestCase
  context "an empty instance" do
    should "raise attribute missing error" do
      assert_raise(Xpay::AttributeMissing) { Xpay::TransactionQuery.new() }
    end
  end

  context "an instance with missing site refence " do
    setup do
      ops = REXML::XPath.first(Xpay.root_xml, "//Operation")
      ops.delete_element "SiteReference"
    end
    should "raise attribute missing error" do
      assert_raise(Xpay::AttributeMissing) { Xpay::TransactionQuery.new(:transaction_reference => "17-9-1908322", :order_reference => "121-1010272211") }
    end
  end
  context "an instance with empty site refence " do
    setup do
      REXML::XPath.first(Xpay.root_xml, "//SiteReference").text = ""
    end
    should "raise attribute missing error" do
      assert_raise(Xpay::AttributeMissing) { Xpay::TransactionQuery.new(:transaction_reference => "17-9-1908322", :order_reference => "121-1010272211") }
    end
  end

  context "a new instance" do
    setup do
      @t = Xpay::TransactionQuery.new({:transaction_reference => "17-9-1908322", :order_reference => "121-1010272211", :site_reference => "site1234"})
    end
    should "have a the same xml as the module" do
      assert_equal @t.request_xml.root.to_s, load_xml_string("transactionquery")
    end

    should "have attributes" do
      assert @t.respond_to? :transaction_reference
      assert @t.respond_to? :order_reference
      assert @t.respond_to? :site_reference
    end
  end
end