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
  end
end