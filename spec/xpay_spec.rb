require_relative './test_helper'

RSpec.describe Xpay do
    let(:xpay) { Xpay }

    it "has standard config xml" do
      expect(xpay.root_xml.class).to equal(REXML::Document)
      expect(xpay.config).to eq(OpenStruct.new(xpay_config("default")))
    end

    xit "has xml document formed to xpay spec" do
      root_element   = xpay.root_xml.root.to_s
      expected_value = load_xml_string("root")
      # require 'pry'
      # binding.pry
      expect(root_element).to eq(expected_value)
    end

    it "loads a new config from yaml file" do
      config = xpay.load_config(File.expand_path(File.dirname(__FILE__) + '/fixtures'))
      expect(config).to be true
    end

    context "with new configuration from yaml file" do
      it "has a new config" do
        new_config = OpenStruct.new(xpay_config("config_load_test"))
        expect(xpay.config).to eq(new_config)
      end

      it "has a new root_xml" do
        root_xml = load_xml_string("config_load_test")
        expect(xpay.root_xml.root.to_s).to eq(root_xml)
      end

      it "has config.port 6000" do
        expect(xpay.config.port).to eq 6000
      end

      it "has an environment" do
        expect(xpay.environment).to eq "development"
      end

      it "has an app root" do
        app_root = File.expand_path(File.dirname(__FILE__) + '/fixtures')
        expect(xpay.app_root).to eq app_root
      end
    end

    xit "loads a new config from hash" do
      expect(xpay.set_config(xpay_config("default"))).to be true
      expect(xpay.config).to eq OpenStruct.new(xpay_config("default"))
      expect(xpay.root_xml.root.to_s).to eq load_xml_string("default_config")
    end
end

