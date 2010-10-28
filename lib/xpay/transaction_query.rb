module Xpay

  class TransactionQuery < Transaction
    attr_accessor :transaction_reference, :order_reference, :site_reference

    def initialize(options={})
      @request_xml = REXML::Document.new(Xpay.root_to_s)
      options.each do |key, value|
        self.send("#{key}=", value) if self.respond_to? key
      end
      create_request
    end

    private
    def create_request
      raise AttributeMissing.new "(2500) TransactionReference or OrderReference need to be present." if (transaction_reference.nil? && order_reference.nil?)
      raise AttributeMissing.new "(2500) SiteReference must be present." if (site_reference.nil? && (REXML::XPath.first(@request_xml, "//SiteReference").text.blank? rescue true))
      REXML::XPath.first(@request_xml, "//Request").attributes["Type"] = "TRANSACTIONQUERY"
      ops = REXML::XPath.first(@request_xml, "//Operation")
      ["TermUrl", "MerchantName"].each { |e| ops.delete_element e }
      (ops.elements["SiteReference"] || ops.add_element("SiteReference")).text = self.site_reference if self.site_reference
      (ops.elements["TransactionReference"] || ops.add_element("TransactionReference")).text = self.transaction_reference if self.transaction_reference
      order = REXML::XPath.first(@request_xml, "//Operation")
      (order.elements["OrderReference"] || order.add_element("OrderReference")).text = self.order_reference if self.order_reference
    end

  end
end