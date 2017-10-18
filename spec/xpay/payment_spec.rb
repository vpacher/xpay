require_relative '../test_helper'

RSpec.describe Xpay::Payment do

  context "an empty payment instance" do
    let(:payment) {Xpay::Payment.new}

    it "has a the same xml as the module" do
      expect(payment.request_xml.root.to_s).to eq Xpay.root_xml.root.to_s
    end

    it "has a response block with return nil" do
      expect(payment.response_block).to be_empty
    end

    it "has a threesecure hash that has only emtpy elements" do
      expect(payment.three_secure).to be_empty
    end
  end

  context "a payment instance from hashes" do
    let(:options) do
      {
          creditcard: credit_card("class_test"),
          operation: operation("class_test"),
          customer: customer("class_test")
      }
    end
    let(:payment) {Xpay::Payment.new(options)}

    it "has a customer instance variable" do
      expect(payment.customer.class).to eq Xpay::Customer
    end
    it "has a operations instance variable" do
      expect(payment.operation.class).to eq Xpay::Operation
    end
    it "has a creditcard instance variable" do
      expect(payment.creditcard.class).to eq Xpay::CreditCard
    end
  end

  context "a payment instance from class instance" do

    let(:options) do
      {
          creditcard: Xpay::CreditCard.new(credit_card("class_test")),
          operation: Xpay::Operation.new(operation("class_test")),
          customer: Xpay::Customer.new(customer("class_test"))
      }
    end
    let(:payment) {Xpay::Payment.new(options)}

    it "has a customer instance variable" do
      expect(payment.customer.class).to eq Xpay::Customer
    end
    it "has a operations instance variable" do
      expect(payment.operation.class).to eq Xpay::Operation
    end
    it "has a creditcard instance variable" do
      expect(payment.creditcard.class).to eq Xpay::CreditCard
    end
  end

  context "an empty payment instance with set 3D secure response" do
    let(:payment) {Xpay::Payment.new}
    before { payment.send("response_xml=", load_xml("response_3d")) }

    it "has a non-empty hash as a response block" do
      expect(payment.response_block).not_to  be_empty
    end

    it "has a non-empty hash as threesecure block" do
      expect(payment.three_secure).not_to  be_empty
    end
  end

  context "a non-empty payment instance with set 3D secure response" do

    let(:options) do
      {
          creditcard: Xpay::CreditCard.new(credit_card("class_test")),
          operation: Xpay::Operation.new(operation("class_test")),
          customer: Xpay::Customer.new(customer("class_test"))
      }
    end
    let(:payment) {Xpay::Payment.new(options)}

    before do
      Xpay::Payment.send(:public, *Xpay::Payment.private_instance_methods)
      payment.send("response_xml=", load_xml("response_3d"))
    end

    it "has a new request_xml after rewrite" do
      payment.rewrite_request_block
      expect(payment.request_xml.root.to_s).to eq load_xml_string("request_rewritten")
    end

    it "has a non-empty hash as a response block" do
      expect(payment.response_block).to_not be_empty
    end

    it "has a non-empty hash as threesecure block" do
      expect(payment.three_secure).to_not be_empty
    end
  end

  context "a payment instance created from xml without PaRes" do
    let(:options) { { xml: load_xml_string("request_rewritten") } }

    it "throws error 2500, PaRes missing" do
      expect { Xpay::Payment.new(options) }.to raise_error(Xpay::PaResMissing)
    end
  end

  context "a payment instance created from xml without PaRes" do
      let(:options) { { xml: load_xml_string("request_rewritten"), :pares => "ABJASDKA+SDKAJ/SGDSAD"} }
      let(:payment) { Xpay::Payment.new(options) }

    it "has a request_xml document" do
      expect(payment.request_xml.class).to eq REXML::Document
    end
  end
end
