require 'logger'
require 'goliath'
require 'em-synchrony/em-redis'

module EY
  module Tea
    module Server

      def self.app
        mocking? ? mock_app : api
      end

      def self.api
        Api.new EM::Protocols::Redis.connect
      end

      def self.mock_app
        Rack::Builder.app do
          use MockGoliath, Server.api
          run Server.api
        end
      end

      def self.mock!
        @mocking = true
      end

      def self.mocking?
        @mocking
      end
    end
  end
end

require 'ey_tea/server/api'

require 'ey_tea/server/mock'
