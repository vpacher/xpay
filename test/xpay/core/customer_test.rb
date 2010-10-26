require 'test_helper'

class CustomerTest < Test::Unit::TestCase
  context "a customer instance" do
    setup do
      @cus = Xpay::Customer.new(customer("class_test"))
      @request_xml = REXML::Document.new(Xpay.root_to_s)
    end
    should "have a title" do
      assert_equal @cus.title, "MR"
    end
    should "have a fullname" do
      assert_equal @cus.fullname, "JOE BLOGGS"
    end
    should "have a firstname" do
      assert_equal @cus.firstname, "Joe"
    end
    should "have a lastname" do
      assert_equal @cus.lastname, "Bloggs"
    end
    should "have a middlename" do
      assert_equal @cus.middlename, "X"
    end
    should "have a namesuffix" do
      assert_equal @cus.namesuffix, "PhD"
    end
    should "have a companyname" do
      assert_equal @cus.companyname, "NotInventedHere.com"
    end
    should "have a street" do
      assert_equal @cus.street, "tonowhere crescent"
    end
    should "have a city" do
      assert_equal @cus.city, "beyond the rainbow on stale bread"
    end
    should "have a stateprovince" do
      assert_equal @cus.stateprovince, "East-West Swampshire"
    end
    should "have a postcode" do
      assert_equal @cus.postcode, "X01 Z10"
    end
    should "have a countrycode" do
      assert_equal @cus.countrycode, "GB"
    end
    should "have a phone" do
      assert_equal @cus.phone, "07950 843 363"
    end
    should "have a email" do
      assert_equal @cus.email, "joe.x.bloggs@notinventedhere.com"
    end
    should "have a http_accept" do
      assert_equal @cus.http_accept, "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    end
    should "have a user_agent" do
      assert_equal @cus.user_agent, "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; GTB5; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; InfoPath.1; .NET4.0C; AskTbGLSV5/5.8.0.12304)"
    end
    should "create a xml document according to xpay spec" do
      @cus.add_to_xml(@request_xml)
      assert_equal(customer_xml_string, @request_xml.root.to_s)
    end
  end

end
