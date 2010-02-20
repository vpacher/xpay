require 'rexml/document'
include REXML

module Xpay
  @xpay_config = {}
  @xpay_xml = {}
  class << self
    def load_configuration(xpay_config, xml_template = "#{RAILS_ROOT}/vendor/plugins/xpay/templates/xpay.xml")
      if File.exist?(xpay_config)
        if defined? RAILS_ENV
          config = YAML.load_file(xpay_config)[RAILS_ENV]
        else
          config = YAML.load_file(xpay_config)
        end
        apply_configuration(config)
        read_xml(xml_template)
      end
    end
    def apply_configuration(config)
      @xpay_config = config
    end
    def read_xml(xml_template)
      f = File.read(xml_template)
      @xpay_xml = REXML::Document.new f
      op = @xpay_xml.root.elements["Request"].elements["Operation"]
      op.elements["SiteReference"].text = @xpay_config['merchant_reference']
      op.elements["MerchantName"].text = @xpay_config['merchant_name']
    end
    def config
      @xpay_config
    end
    def pxml
      @xpay_xml
    end
    def test_data
      cc = {:type => "Visa", :number => "4111111111111111", :securitycode => "123", :expirydate => "05/10"}
      operation = {:amount => 1000, :currency => "USD", :termurl => "http://localhost/gateway_callback"}
      customer = {:firstname => "Volker", :lastname => "Pacher"}
      return {:operation => operation, :customer => customer, :creditcard => cc}
    end
    private
    def add_certificate(doc)
      cer = doc.root.add_element("Certificate")
      cer.text = Payment.load_certificate
      return doc
    end
    def load_certificate
      mycert = ''
      File.open(@xpay_config['path_to_cert'], "r") { |f| mycert = f.read}
      mycert.chomp
    end

    def xpay(request_block)
      # adding the certificate as last step before writing it to the socket, this way it will not be stored by accident in the case of 3DAUTH
      r_block = add_certificate(request_block)

      # open the socket and write to it, wait for response, read it, close the port
      # TODO adding port as option to yaml file, investigate option of different host
      a = TCPSocket.open("localhost",5000)
      a.write(r_block.to_s)
      res = a.read()
      a.close

      # create an xml document, use everything from the start of <ResponseBlock to the end, discard header and status etc
      response_block = REXML::Document.new res[res.index("<ResponseBlock"), res.length]
      # extract the action code
      action_code = REXML::XPath.first(response_block, "//Result").text.to_i
      return response_block, action_code
    end
  end
  class XpayTransaction < ActiveRecord::Base

  end
  class Payment
    attr_accessor :operation
    def initialize(options={})
      @xml = Xpay.pxml
      set_creditcard(options[:creditcard])
      set_customer(options[:customer])
      set_operation(options[:operation])
    end
    def operation
      Hash.from_xml(@xml.root.elements["Request"].elements["Operation"].to_s)
    end
    def xml
      @xml
    end

    private
    def set_creditcard(block)
      cc = @xml.root.elements["Request"].elements["PaymentMethod"].elements["CreditCard"]
      cc.elements["Type"].text = block[:type]
      cc.elements["Number"].text = block[:number]
      cc.elements["Issue"].text = block[:issue] unless block[:issue].blank?
      cc.elements["StartDate"].text = block[:startdate] unless block[:startdate].blank?
      cc.elements["SecurityCode"].text = block[:securitycode]
      cc.elements["ExpiryDate"].text = block[:expirydate]
    end
    def set_customer(block)
      # Root element for all customer info
      cus = @xml.root.elements["Request"].elements["CustomerInfo"]

      # User agent and Accept encoding goes here
      block[:user_agent].blank? ? cus.delete_element("UserAgent") : cus.elements["UserAgent"].text = block[:user_agent]
      block[:accept].blank? ? cus.delete_element("Accept") : cus.elements["Accept"].text = block[:accept]

      # Postal node -> name and adress
      postal = cus.elements["Postal"]

      # Customer Name
      name = postal.elements["Name"]
      block[:nameprefix].blank? ? name.delete_element("NamePrefix") : name.elements["NamePrefix"].text = block[:nameprefix]
      name.elements["FirstName"].text = block[:firstname]
      block[:middlename].blank? ? name.delete_element("MiddleName") : name.elements["MiddleName"].text = block[:middlename]
      name.elements["LastName"].text = block[:lastname]
      block[:namesuffix].blank? ? name.delete_element("NameSuffix") : name.elements["NameSuffix"].text = block[:namesuffix]
      
      # Address and Company name
      block[:company_name].blank? ? name.delete_element("Company") : name.elements["Company"].text = block[:company_name]
      block[:street].blank? ? name.delete_element("Street") : name.elements["Street"].text = block[:street]
      block[:city].blank? ? name.delete_element("City") : name.elements["City"].text = block[:city]
      block[:state].blank? ? name.delete_element("StateProv") : name.elements["StateProv"].text = block[:state]
      block[:zip].blank? ? name.delete_element("PostalCode") : name.elements["PostalCode"].text = block[:zip]
      block[:country_code].blank? ? name.delete_element("CountryCode") : name.elements["CountryCode"].text = block[:country_code]

      # Telephone
      telco = cus.elements["Telecom"]
      block[:phone_number].blank? ? telco.delete_element("Phone") : telco.elements["Phone"].text = block[:phone_number]

      #email
      online_info = cus.elements["Online"]
      block[:email].blank? ? online_info.delete_element("Email") : online_info.elements["Email"].text = block[:email]
    end
    def set_operation(block)
      ops = @xml.root.elements["Request"].elements["Operation"]
      ops.elements["Amount"].text = block[:amount]
      ops.elements["Currency"].text = block[:currency] unless block[:currency].blank?
      ops.elements["SettlementDay"].text = block[:settlementday] unless block[:settlementday].blank?
      ops.elements["TermUrl"].text = block[:termurl] unless block[:termurl].blank?
    end
  end
end