module Xpay
  class Operation
    attr_accessor :auth_type, :currency, :settlement_day, :callback_url, :site_reference, :merchant_name,
                  :order_reference, :order_info

    def initialize(options={})
      if !options.nil? && options.is_a?(Hash)
        options.each do |key, value|
          self.send("#{key}=", value) if self.respond_to? key
        end
      end
    end

    def add_to_xml(doc)
      req = REXML::XPath.first(doc, "//Request")
      req.attributes["Type"] = self.auth_type if self.auth_type
      REXML::XPath.first(doc, "//SiteReference").text(self.site_reference) if self.site_reference
      ops = REXML::XPath.first(doc, "//Operation")
      (ops.elements["Amount"] || ops.add_element("Amount")).text = self.amount if self.amount
      (ops.elements["Currency"] || ops.add_element("Currency")).text = self.currency if self.currency
      (ops.elements["MerchantName"] || ops.add_element("MerchantName")).text = self.merchant_name if self.merchant_name
      (ops.elements["TermUrl"] || ops.add_element("TermUrl")).text = self.callback_url if self.callback_url
      if (self.order_reference || self.order_info)
        req.delete_element("Order")
        order = req.add_element("Order")
        order.add_element("OrderReference").add_text(self.order_reference) if self.order_reference
        order.add_element("OrderInformation").add_text(self.order_info) if self.order_info
      end
    end

    def amount=(new_val)
      @amount = new_val.to_s
    end

    def amount
      @amount
    end
  end
end
