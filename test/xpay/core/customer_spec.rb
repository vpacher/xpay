require_relative '../../test_helper'

RSpec.describe Xpay::Customer do

    let(:test_customer) { Xpay::Customer.new(customer("class_test")) }
    let(:request_xml)   { REXML::Document.new(Xpay.root_to_s) }

    it "has a title" do
      expect(test_customer.title).to eq "MR"
    end

    it "has a fullname" do
      expect(test_customer.fullname).to eq "JOE BLOGGS"
    end

    it "has a firstname" do
      expect(test_customer.firstname).to eq "Joe"
    end

    it "has a lastname" do
      expect(test_customer.lastname).to eq "Bloggs"
    end

    it "has a middlename" do
      expect(test_customer.middlename).to eq "X"
    end

    it "has a namesuffix" do
      expect(test_customer.namesuffix).to eq "PhD"
    end

    it "has a companyname" do
      expect(test_customer.companyname).to eq "NotInventedHere.com"
    end

    it "has a street" do
      expect(test_customer.street).to eq "tonowhere crescent"
    end

    it "has a city" do
      expect(test_customer.city).to eq "beyond the rainbow on stale bread"
    end

    it "has a stateprovince" do
      expect(test_customer.stateprovince).to eq "East-West Swampshire"
    end

    it "has a postcode" do
      expect(test_customer.postcode).to eq "X01 Z10"
    end

    it "has a countrycode" do
      expect(test_customer.countrycode).to eq "GB"
    end

    it "has a phone" do
      expect(test_customer.phone).to eq "07950 843 363"
    end

    it "has a email" do
      expect(test_customer.email).to eq "joe.x.bloggs@notinventedhere.com"
    end

    it "has a http_accept" do
      expect(test_customer.http_accept).to eq "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    end

    it "has a user_agent" do
      expect(test_customer.user_agent).to eq "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; GTB5; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; InfoPath.1; .NET4.0C; AskTbGLSV5/5.8.0.12304)"
    end

    it "creates a xml document according to xpay spec" do
      test_customer.add_to_xml(request_xml)
      expect(request_xml.root.to_s).to eq load_xml_string('customer')
    end
end
