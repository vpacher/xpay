module Xpay

  # This class allows you to query the status of a transaction processed with Xpay
  # the following attributes are required:
  # either a TransactionReference or your own OrderReference from a previous transaction
  # and your SiteReference if not already set in the config, you can also pass it to overwrite it for this transaction
  class TransactionQuery < Transaction
    attr_accessor :transaction_reference, :order_reference, :site_reference, :site_alias

    def initialize(options={})
      @request_xml = REXML::Document.new(Xpay.root_to_s)
      options.each do |key, value|
        self.send("#{key}=", value) if self.respond_to? key
      end
      create_request
    end

    def query
      @response_xml = process
      response_code
    end

    # The response_block is a hash and can have one of several values:
    # the follwing values are always present after a transaction and can be queried to gain further details of the transaction:
    #   * result_code:
    #       0 for failure, check error_code for further details
    #       1 transaction was succesful
    #       2 transaction was denied
    #   * transaction_reference
    #   * transactionverifier
    #   * transaction_time
    #   * auth_code
    #   * amount
    #   * the order reference
    def response_block
      create_response_block
    end

    private

    # Write the xml document needed for processing, fill in elements need and delete unused ones from the root_xml
    # raises an error if any necessary elements are missing
    def create_request
      raise AttributeMissing.new "(2500) TransactionReference or OrderReference need to be present." if (transaction_reference.nil? && order_reference.nil?)
      raise AttributeMissing.new "(2500) SiteReference must be present." if (site_reference.nil? && (REXML::XPath.first(@request_xml, "//SiteReference").text.blank? rescue true))
      REXML::XPath.first(@request_xml, "//Request").attributes["Type"] = "TRANSACTIONQUERY"
      ops = REXML::XPath.first(@request_xml, "//Operation")
      ["TermUrl", "MerchantName", "Currency", "SettlementDay"].each { |e| ops.delete_element e }
      (ops.elements["SiteReference"] || ops.add_element("SiteReference")).text = self.site_reference if self.site_reference
      (ops.elements["TransactionReference"] || ops.add_element("TransactionReference")).text = self.transaction_reference if self.transaction_reference
      order = REXML::XPath.first(@request_xml, "//Operation")
      (order.elements["OrderReference"] || order.add_element("OrderReference")).text = self.order_reference if self.order_reference
      root = @request_xml.root
      (root.elements["Certificate"] || root.add_element("Certificate")).text = self.site_alias if self.site_alias
    end

    def create_response_block
      @response_xml.is_a?(REXML::Document) ?
              {
                result_code:           get_response_value(@response_xml, '//Result', true),
                transaction_reference: get_response_value(@response_xml, '//TransactionReference'),
                transactionverifier:   get_response_value(@response_xml, '//TransactionVerifier'),
                transaction_time:      get_response_value(@response_xml, '//TransactionCompletedTimestamp'),
                auth_code:             get_response_value(@response_xml, '//AuthCode'),
                amount:                get_response_value(@response_xml, '//Amount', true),
                order_reference:       get_response_value(@response_xml, '//OrderReference')
              } : {}
    end

    def get_response_value(response_xml, xpath, cast_to_i = false)
      object = REXML::XPath.first(response_xml, xpath)
      value = object ? object.text : nil
      value = value.to_i if (value && cast_to_i)
      value
    end
  end
end