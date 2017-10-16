require 'socket'
require 'rspec'

TCP_NEW = TCPSocket.method(:new) unless defined? TCP_NEW

#
# Example:
#   mock_tcp_next_request("<xml>junk</xml>")
#
class FakeTCPSocket

  def write(some_text = nil)
  end

  def read
    @canned_response
  end

  def set_canned(response)
    @canned_response = response
  end

  def close
    # unmock_tcp
  end
end

def mock_tcp_next_request(string)
  TCPSocket.stub(:open).with('localhost', 5000) {
    cm = FakeTCPSocket.new
    cm.set_canned(string)
    cm
  }
end

def unmock_tcp
  TCPSocket.stub(:open).and_return { TCP_NEW.call }
end
