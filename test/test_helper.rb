require 'rubygems'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/test_case'
require 'active_support/time'
require 'shoulda'
require 'fileutils'
require 'log_buddy'
require 'ostruct'
require 'rexml/document'
require 'Yaml'
require 'xpay'

def credit_card(which)
  YAML::load(ERB.new(IO.read(File.expand_path(File.dirname(__FILE__) + '/fixtures/creditcards.yml'))).result)[which]
end

def customer(which)
  YAML::load(ERB.new(IO.read(File.expand_path(File.dirname(__FILE__) + '/fixtures/customer.yml'))).result)[which]
end

def operation(which)
  YAML::load(ERB.new(IO.read(File.expand_path(File.dirname(__FILE__) + '/fixtures/operation.yml'))).result)[which]
end

def load_xml(which='')
  REXML::Document.new(File.open(File.expand_path(File.dirname(__FILE__) + "/fixtures/#{which}.xml")))
end

def load_xml_string(which='')
  load_xml(which).root.to_s
end

def xpay_config(which)
  YAML::load(IO.read(File.expand_path(File.dirname(__FILE__) + '/fixtures/xpay_defaults.yml')))[which]
end

log_dir = File.expand_path('../../log', __FILE__)
FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
logger = Logger.new(log_dir + '/test.log')

LogBuddy.init(:logger => logger)


