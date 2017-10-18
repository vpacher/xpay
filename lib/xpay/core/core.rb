module Xpay
  class Core
    def initialize(options={})
      options.each {|key, value| self.send("#{key}=", value) if self.respond_to? key} if (!options.nil? && options.is_a?(Hash))
    end
  end
end