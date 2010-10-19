module Xpay
  class Transaction
    @request_xml = REXML::Document # Request XML document
    @response_xml = REXML::Document # Response XML document, received from secure trading
    @three_secure = {} # 3D Secure information hash, used for redirecting to 3D Secure server in form

    def process(r_block)
      a = TCPSocket.open("localhost", 5000)
      a.write(r_block.to_s)
      res = a.read()
      a.close
      # create an xml document, use everything from the start of <ResponseBlock to the end, discard header and status etc and return it
      return REXML::Document.new res[res.index("<ResponseBlock"), res.length]
    end

    def request
      @request_xml
    end
    def respons
      @response_xml
    end
  end
end