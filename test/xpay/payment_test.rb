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

    should "have a response block with return nil" do
      assert @p.response_block.empty?
    end

    should "have a threesecure hash that has only emtpy elements" do
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
  context "an empty payment instance with set 3D secure response" do
    setup do
      @p = Xpay::Payment.new()
      @p.send("response_xml=", operation_xml("response_3d"))
    end

    should "have a non-empty hash as a response block" do
      assert !@p.response_block.empty?
    end

    should "have a non-empty hash as threesecure block" do
      assert !@p.three_secure.empty?
    end
  end
  context "a non-empty payment instance with set 3D secure response" do
    setup do
      Xpay::Payment.send(:public, *Xpay::Payment.private_instance_methods)
      options = {:creditcard => Xpay::CreditCard.new(credit_card("class_test")), :operation => Xpay::Operation.new(operation("class_test")), :customer => Xpay::Customer.new(customer("class_test"))}
      @p = Xpay::Payment.new(options)
      @p.send("response_xml=", operation_xml("response_3d"))

    end
    should "have a new request_xml after rewrite" do
      @p.rewrite_request_block
      assert_equal operation_xml_string("request_rewritten"), @p.request_xml.root.to_s
    end

    should "have a non-empty hash as a response block" do
      assert !@p.response_block.empty?
    end

    should "have a non-empty hash as threesecure block" do
      assert !@p.three_secure.empty?
    end
  end

  context "a payment instance created from xml without PaRes" do
    should "throw error 2500, PaRes missing" do
      options = {:xml => operation_xml_string("request_rewritten")}
      assert_raise(Xpay::PaResMissing) {Xpay::Payment.new(options)}
    end
  end
  context "a payment instance created from xml without PaRes" do
    setup do
      options = {:xml => operation_xml_string("request_rewritten"), :pares => "ABJASDKA+SDKAJ/SGDSAD"}
      @p = Xpay::Payment.new(options)
    end
    should "should have a request_xml document" do
      assert_instance_of(REXML::Document, @p.request_xml)
    end
  end
end
