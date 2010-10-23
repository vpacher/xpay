require 'rubygems'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/test_case'
require 'shoulda'
require 'fileutils'
require 'log_buddy'
require 'ostruct'
require 'rexml/document'

def credit_card(which)
  conf = YAML::load(ERB.new(IO.read(File.expand_path(File.dirname(__FILE__) + '/fixtures/creditcards.yml'))).result)[which]
end
def customer(which)
  conf = YAML::load(ERB.new(IO.read(File.expand_path(File.dirname(__FILE__) + '/fixtures/customer.yml'))).result)[which]
end
def customer_xml_string
  x = REXML::Document.new(File.open(File.expand_path(File.dirname(__FILE__) + '/fixtures/customer.xml'))).root.to_s
end

def root_xml_string
  x = REXML::Document.new(File.open(File.expand_path(File.dirname(__FILE__) + '/fixtures/root.xml'))).root.to_s
end

def xpay_config(which)
  YAML::load(IO.read(File.expand_path(File.dirname(__FILE__) + '/fixtures/xpay_defaults.yml')))[which]
end

log_dir = File.expand_path('../../log', __FILE__)
FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
logger = Logger.new(log_dir + '/test.log')

LogBuddy.init(:logger => logger)


