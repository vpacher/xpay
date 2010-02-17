require 'rexml/document'
include REXML

module Xpay
  @xpay_config = {}
  
  class << self
    def load_configuration(xpay_config)
      if File.exist?(xpay_config)
        if defined? RAILS_ENV
          config = YAML.load_file(xpay_config)[RAILS_ENV]
        else
          config = YAML.load_file(xpay_config)
        end
        apply_configuration(config)
      end
    end
    def apply_configuration(config)
      @xpay_config = config
    end
    def config
      @xpay_config
    end

    private

    def add_certificate(doc)
      cer = doc.root.add_element("Certificate")
      cer.text = Payment.cert_load
      return doc
    end
    def cert_load
      mycert = ''
      File.open(@xpay_config['path_to_cert'], "r") { |f| mycert = f.read}
      mycert.chomp
    end

    def xpay(request_block)
      r_block = add_certificate(request_block)
      a = TCPSocket.open("localhost",5000)
      a.write(r_block.to_s)
      res = a.read()
      a.close
      response_block = REXML::Document.new res[res.index("<ResponseBlock"), res.length]
      action_code = REXML::XPath.first(response_block, "//Result").text.to_i
      return response_block, action_code
    end
  end
end