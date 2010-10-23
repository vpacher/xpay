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

    should "load a new config from yaml file" do
      assert @xpay.load_config(File.expand_path(File.dirname(__FILE__)+ '/fixtures'))
    end

    context "with new configuration" do

      should "have a new config" do
        assert_equal @xpay.config, OpenStruct.new(xpay_config("config_load_test"))
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
