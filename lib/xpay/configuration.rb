require 'singleton'
require 'erb'
require 'ostruct'
module Xpay
  class Configuration
    include Singleton
    attr_accessor :app_root
    attr_reader :environment, :configuration

    def initialize(app_root = Dir.pwd)
      self.app_root = RAILS_ROOT if defined?(RAILS_ROOT)
      #self.configuration = OpenStruct.new
      self.port = 5000
      parse_config
    end

    def self.environment
      Thread.current[:xpay_environment] ||= begin
        if defined?(RAILS_ENV)
          RAILS_ENV
        else
          ENV['RAILS_ENV'] || 'development'
        end
      end
    end

    def environment
      self.class.environment
    end

    def port
      @port
    end

    def port=(port)
      @port = port
    end

    private
    def parse_config
      path = "#{app_root}/config/xpay.yml"
      return unless File.exists?(path)

      conf = YAML::load(ERB.new(IO.read(path)).result)[environment]

      conf.each do |key, value|
        self.send("#{key}=", value) if self.respond_to?("#{key}=")
      end unless conf.nil?
    end
  end
end