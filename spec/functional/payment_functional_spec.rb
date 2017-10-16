require_relative '../test_helper'
require_relative '../fake_tcp_socket'

RSpec.describe 'PaymentFunction' do
  context "with rightly formed request" do
    context "a succesful payment with no 3D required" do
        let(:options) {
          {
            creditcard: Xpay::CreditCard.new(credit_card("visa_no3d_auth")),
            operation:  Xpay::Operation.new(operation("test_1")),
            customer:   Xpay::Customer.new(customer("test_1"))
          }
        }
        let(:payment)    { Xpay::Payment.new(options) }
        let(:response)   { load_xml_string("response_non3d") }

        before(:example) { mock_tcp_next_request(response) }

      it "returns 1 on make_payment" do
        expect(payment.make_payment).to eq 1
      end
    end

    context "a payment with redirect to AUTH request" do
        let(:options) do
          {
              creditcard: Xpay::CreditCard.new(credit_card("visa_no3d_decl")),
              operation:  Xpay::Operation.new(operation("test_1")),
              customer:   Xpay::Customer.new(customer("test_1"))}
        end
        let(:payment)    { Xpay::Payment.new(options) }
        let(:response)   { load_xml_string("response_doauth") }

        before(:example) { mock_tcp_next_request(response) }

      it "returns 2 on make_payment" do
        expect(payment.make_payment).to eq 2
      end

      context "a visa payment with 3D required" do
          let(:options) do
            {
                creditcard: Xpay::CreditCard.new(credit_card("visa_3d_auth")),
                operation:  Xpay::Operation.new(operation("test_1")),
                customer:   Xpay::Customer.new(customer("test_1"))}
          end
          let(:payment) { Xpay::Payment.new(options) }
          let(:response)   { load_xml_string("response_3d") }

          before(:example) { mock_tcp_next_request(response) }

        it "returns -1 on make_payment" do
          expect(payment.make_payment).to eq -1
        end
      end
    end
  end

  context "with wrongly formed request" do
    context "a visa with invalid datetime format" do
      let(:options) do
        {
            creditcard: Xpay::CreditCard.new(credit_card("visa_3d_auth")),
            operation:  Xpay::Operation.new(operation("test_1")),
            customer:   Xpay::Customer.new(customer("test_1"))}
      end
      let(:payment) { Xpay::Payment.new(options) }
      let(:response)   { load_xml_string("response") }

      before(:example) { mock_tcp_next_request(response) }

      it "returns 0 on make_payment" do
        expect(payment.make_payment).to eq 0
      end
      it "returns '(3100) Invalid ExpiryDate' in response block error code" do
        payment.make_payment
        expect(payment.response_block[:error_code]).to eq '(3100) Invalid ExpiryDate'
      end
    end
  end
end