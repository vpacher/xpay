require 'rexml/document'
require 'rexml/xmldecl'
require 'ostruct'
require 'erb'
require 'xpay/transaction'

module Xpay
  # These are the default settings. You can change them by placing YAML file into config/xpay.yml with settings for each environment.
  # Alternatively you can change the settings by calling the config setter for each attribute for example:
  # Xpay.config.alias = "your_new_alias"
  # Another option is to call Xpay.set_config with a hash containing the attributes you want to change
  #
  # merchant_name:  CompanyName
  # version:        3.51              'this is the only supported version at the moment and has to be 3.51, as String'
  # alias:          site12345
  # site_reference: site12345
  # port:           5000               'this needs to be an Integer'
  # default_query:  ST3DCARDQUERY      'defaults to 3D Card query if not otherwise specified'
  # settlement_day: 1                  'this needs to be a String'
  # default_currency: GBP

  autoload :Payment, 'xpay/payment'
  autoload :TransactionQuery, 'xpay/transaction_query'
  autoload :CreditCard, 'xpay/core/creditcard'
  autoload :Customer, 'xpay/core/customer'
  autoload :Operation, 'xpay/core/operation'

  @xpay_config = OpenStruct.new({
                                        "merchant_name" => "CompanyName",
                                        "version" => "3.51",
                                        "alias" => "site12345",
                                        "site_reference" => "site12345",
                                        "port" => 5000,
                                        "callback_url" => "http://localhost/gateway_callback",
                                        "default_query" => "ST3DCARDQUERY",
                                        "settlement_day" => "1",
                                        "default_currency" => "GBP"
                                })
  class XpayError < StandardError
    attr_reader :data

    def initialize(data)
      @data = data
      super
    end
  end

  class PaResMissing      < XpayError; end
  class General           < XpayError; end

  class << self
    attr_accessor :app_root, :environment

    def load_config(app_root = Dir.pwd)
      self.app_root = (RAILS_ROOT if defined?(RAILS_ROOT)) || app_root
      self.environment = (RAILS_ENV if defined?(RAILS_ENV)) || "development"
      parse_config
      return true
    end


    def root_xml
      @request_xml ||= create_root_xml
    end

    def root_to_s
      self.root_xml.to_s
    end


    def config
      @xpay_config
    end

    def set_config(conf)
      conf.each do |key, value|
        @xpay_config.send("#{key}=", value) if @xpay_config.respond_to? key
      end
      return true
    end

    private
    def parse_config
      path = "#{app_root}/config/xpay.yml"
      return unless File.exists?(path)
      conf = YAML::load(ERB.new(IO.read(path)).result)[environment]
      self.set_config(conf)
    end

    def create_root_xml
      r = REXML::Document.new
      r << REXML::XMLDecl.new("1.0", "iso-8859-1")
      rb = r.add_element "RequestBlock", {"Version" => config.version}
      request = rb.add_element "Request", {"Type" => config.default_query}
      operation = request.add_element "Operation"
      site_ref = operation.add_element "SiteReference"
      site_ref.text = config.site_reference
      if config.default_query == "ST3DCARDQUERY"
        mn = operation.add_element "MerchantName"
        mn.text = config.merchant_name
        tu = operation.add_element "TermUrl"
        tu.text = config.callback_url
      end
      cer = rb.add_element "Certificate"
      cer.text = config.alias
      return r
    end

  end
end