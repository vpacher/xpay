require_relative '../test_helper'

RSpec.describe Xpay::TransactionQuery do

  it "raises attribute missing error with an empty instance" do
    expect { Xpay::TransactionQuery.new }.to raise_error(Xpay::AttributeMissing)
  end

  context "an instance with missing site refence" do
    let(:options) do
      {
          transaction_reference: "17-9-1908322",
          order_reference: "121-1010272211"
      }
    end
    let(:ops) { REXML::XPath.first(Xpay.root_xml, "//Operation") }

    after do
      site_reference = ops.add_element "SiteReference"
      site_reference.text = '1234'
    end

    it "raises attribute missing error" do
      ops.delete_element "SiteReference"
      expect { Xpay::TransactionQuery.new(options) }.to raise_error(Xpay::AttributeMissing)
    end
  end

  context "an instance with empty site refence" do
    let(:options) do
      {
          transaction_reference: "17-9-1908322",
          order_reference: "121-1010272211"
      }
    end

    after { REXML::XPath.first(Xpay.root_xml, "//SiteReference").text = '1234' }

    it "raises attribute missing error" do
      REXML::XPath.first(Xpay.root_xml, "//SiteReference").text = ''
      expect { Xpay::TransactionQuery.new(options) }.to raise_error Xpay::AttributeMissing
    end
  end

  context "a new instance with only a transaction reference" do
    let(:transaction) { Xpay::TransactionQuery.new({:transaction_reference => "17-9-1908322"}) }

    it "instantiates without error" do
      expect(transaction).to be_a Xpay::TransactionQuery
    end
  end

  context "a new instance with only a order reference" do
      let(:transaction) { Xpay::TransactionQuery.new({:order_reference => "17-9-1908322"}) }

    it "instantiates without error" do
      expect(transaction).to be_a Xpay::TransactionQuery
    end
  end

  context "a new instance" do
    let(:transaction) do
      options = { transaction_reference: "17-9-1908322", order_reference: "121-1010272211", site_reference: "site1234" }
      Xpay::TransactionQuery.new(options)
    end

    it "has a the same xml as the module" do
      expect(transaction.request_xml.root.to_s).to eq load_xml_string("transactionquery")
    end

    it "has an empty repsonse block" do
      expect(transaction.response_block).to be_empty
    end

    it "has attributes" do
      expect(transaction).to respond_to :transaction_reference
      expect(transaction).to respond_to :order_reference
      expect(transaction).to respond_to :site_reference
      expect(transaction).to respond_to :site_alias
    end

    context "given a response block" do
      before do
        Xpay::TransactionQuery.send(:public, *Xpay::TransactionQuery.private_instance_methods)
        transaction.send("response_xml=", load_xml("transactionquery_response"))
      end

      it "has a response block" do
        expect(transaction.response_block).to_not be_empty
      end

      it "has values" do
        rb = transaction.response_block
        expect(rb[:transaction_reference]).to eq  "2-2-35117"
        expect(rb[:auth_code]).to eq  "AUTH CODE: ab123"
        expect(rb[:result_code]).to eq  1
        expect(rb[:transaction_time]).to eq  "2004-08-31 16:17:03"
        expect(rb[:transactionverifier]).to eq  "ApTtGHQ/WUQYRj"
        expect(rb[:order_reference]).to eq  "orderref0001"
      end
    end
  end
end