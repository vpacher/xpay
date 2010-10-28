require 'test_helper'
require 'xpay'

class XpayTest < Test::Unit::TestCase
  context "the xpay module" do
    setup do
      @xpay = Xpay
    end

    should "have standard config xml" do
      assert_kind_of(REXML::Document,@xpay.root_xml)
      assert_equal @xpay.config, OpenStruct.new(xpay_config("default"))
    end
    should "have xml document formed to xpay spec" do
      assert_equal load_xml_string("root"), @xpay.root_xml.root.to_s
    end
    should "load a new config from yaml file" do
      assert @xpay.load_config(File.expand_path(File.dirname(__FILE__)+ '/fixtures'))
    end

    context "with new configuration" do

      should "have a new config" do
        assert_equal @xpay.config, OpenStruct.new(xpay_config("config_load_test"))
        d {@xpay.root_xml.to_s}
      end

      should "have an environment" do
        assert_equal @xpay.environment, "development"
      end

      should "have an app root" do
        assert_equal @xpay.app_root, File.expand_path(File.dirname(__FILE__) + '/fixtures')
      end
    end

    should "load a new config from hash" do
      assert @xpay.set_config(xpay_config("default"))
      assert_equal @xpay.config, OpenStruct.new(xpay_config("default"))
    end

  end
end
