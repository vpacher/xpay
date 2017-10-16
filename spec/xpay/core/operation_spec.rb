require_relative '../../test_helper'

RSpec.describe Xpay::Operation do
  context "an operation instance" do
      let(:ops)         { Xpay::Operation.new(operation("class_test")) }
      let(:request_xml) { REXML::Document.new(Xpay.root_to_s) }

    it "has an auth_type" do
      expect(ops.auth_type).to eq "AUTH"
    end

    it "has a currency" do
      expect(ops.currency).to eq "USD"
    end

    it "has a amount=" do
      expect(ops.amount).to eq "1000"
    end

    it "has a settlement_day" do
      expect(ops.settlement_day).to eq "3"
    end

    it "has a callback_url" do
      expect(ops.callback_url).to eq "https://localhost/3dcallback"
    end

    it "has a site_reference" do
      expect(ops.site_reference).to eq "site56987"
    end

    it "has a site_alias" do
      expect(ops.site_alias).to eq "site56987"
    end

    it "has a merchant_name" do
      expect(ops.merchant_name).to eq "TestMerchant"
    end

    it "has a order_reference" do
      expect(ops.order_reference).to eq "TestOrder1245"
    end

    it "has a order_info" do
      expect(ops.order_info).to eq "TestOrderInfo"
    end

    it "creates an xml document according to xpay spec" do
     ops.add_to_xml(request_xml)
      expect(request_xml.root.to_s).to eq load_xml_string("operation")
    end
  end
end
