require_relative '../test_helper'
require_relative '../fake_tcp_socket'

RSpec.describe 'TransactionFunctionalTest' do

  context "a visa succesful no 3D payment" do
    let(:options) do
      {
          transaction_reference: 'transaction_reference',
          site_reference: 'testoutlet12092',
          site_alias: 'testoutlet12092'
      }
    end

    let(:transaction) {Xpay::TransactionQuery.new(options)}
    let(:response) {load_xml_string("response_non3d")}

    before do
      mock_tcp_next_request(response)
      transaction.query
    end

    it "has a non empty response block" do
      expect(transaction.response_block[:result_code]).to eq 1
    end
  end
end