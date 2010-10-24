module Xpay
  require 'socket'

  # The transaction class is the parent class of all Transactions be it Payment, Refund or Paypal etc.
  # it provides underlying methods which all transactions have in common
  # It should not be instantiated by itself

  class Transaction

    attr_accessor :request_xml, :response_xml, :response_block
    attr_reader :three_secure

    def process()
      a = TCPSocket.open("localhost", Xpay.config.port)
      a.write(self.request_xml.to_s + "\n")
      res = a.read()
      a.close
      # create an xml document, use everything from the start of <ResponseBlock to the end, discard header and status etc and return it
      return REXML::Document.new res[res.index("<ResponseBlock"), res.length]
    end

    def request_method
      @request_method ||= REXML::XPath.first(@request_xml, "//Request").attributes["Type"]
    end

    def response_code
      @response_code ||= REXML::XPath.first(@response_xml, "//Result").text.to_i rescue -1
    end

  end
end