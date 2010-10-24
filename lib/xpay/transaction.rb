module Xpay
  class Transaction
    attr_accessor :request_xml
    attr_reader :response_xml, :three_secure

    def process()
      a = TCPSocket.open("localhost", 5000)
      a.write(self.request_xml.to_s)
      res = a.read()
      a.close
      # create an xml document, use everything from the start of <ResponseBlock to the end, discard header and status etc and return it
      return REXML::Document.new res[res.index("<ResponseBlock"), res.length]
    end

    def request_method
      @request_method ||= REXML::XPath.first(@request_xml, "//Request").attributes["Type"] rescue "not set"
    end

    def response_code
      @response_code ||= REXML::XPath.first(@response_xml, "//Result").text.to_i rescue -1
    end

  end
end