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

require 'htttee/client/ext/net/http'
require 'htttee/client/consumer'
