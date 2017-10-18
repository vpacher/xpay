require_relative '../../test_helper'

RSpec.describe Xpay::CreditCard do
  context "a creditcard instance" do
    let(:test_credit_card) { Xpay::CreditCard.new(credit_card("class_test")) }

    it "has a credit card type" do
      expect(test_credit_card.card_type).to eq "Visa"
    end

    it "has a partly hidden credit card number" do
      expect(test_credit_card.number).to eq "xxxxxxxxxxxx1111"
    end
    
    it "has an expiry date" do
      valid_until = test_credit_card.valid_until
      expect(valid_until.class).to eq String
      expect(valid_until).to match /\A\d{2}\/\d{2}/
      expect(valid_until.length).to eq 5
    end

    it "has an start date" do
      valid_from = test_credit_card.valid_from
      expect(valid_from.class).to eq String
      expect(valid_from).to match /\A\d{2}\/\d{2}/
      expect(valid_from.length).to eq 5
    end

    it "has an issue number" do
     expect(test_credit_card.issue).to eq "1"
    end
  end
end
