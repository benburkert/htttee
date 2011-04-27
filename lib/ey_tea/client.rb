require 'net/http'
require 'rack/client'
#require 'uuidtools'

module EY
  module Tea
    module Client
      def self.new(*a)
        Consumer.new(*a)
      end
    end
  end
end

require 'ey_tea/client/ext/net/http'
require 'ey_tea/client/consumer'
