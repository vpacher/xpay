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

    should "have an empty repsonse block" do
      assert @t.response_block.empty?
    end

    should "have attributes" do
      assert @t.respond_to? :transaction_reference
      assert @t.respond_to? :order_reference
      assert @t.respond_to? :site_reference
    end

    context "given a response block" do
      setup do
        Xpay::TransactionQuery.send(:public, *Xpay::TransactionQuery.private_instance_methods)
        @t.send("response_xml=", load_xml("transactionquery_response"))
      end

      should "have a response block" do
        assert !@t.response_block.empty?
      end

      should "have values" do
        rb = @t.response_block
        assert_equal "2-2-35117", rb[:transaction_reference]
        assert_equal "AUTH CODE: ab123", rb[:auth_code]
        assert_equal 1, rb[:result_code]
        assert_equal "2004-08-31 16:17:03", rb[:transaction_time]
        assert_equal "ApTtGHQ/WUQYRj", rb[:transactionverifier]
        assert_equal "orderref0001", rb[:order_reference]
      end
    end
  end

end