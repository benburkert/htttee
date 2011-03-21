require 'thin'
require 'yajl'
require 'sinatra/base'
require 'em-redis'

module EY
  module Tea
    module Server

      def self.app
        mocking? ? mock_app : api
      end

      def self.api
        Api.new EM::Protocols::Redis.connect, PubSubRedis.connect
      end

      def self.mock_app
        Rack::Builder.app do
          use MockThin
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

require 'ey_tea/server/pubsub_redis'

require 'ey_tea/server/api'

require 'ey_tea/server/deferrable_body'
require 'ey_tea/server/mock_thin'
