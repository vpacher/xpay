require 'rubygems'
require 'active_support'
require 'active_support/core_ext'
require 'fileutils'
require 'ostruct'
require 'rexml/document'
require 'Yaml'
require 'xpay'

require 'simplecov'
SimpleCov.start


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
