require 'thin'
require 'yajl'
require 'sinatra/base'
require 'em-redis'

EM.epoll

module EY
  module Tea
    module Server

      def self.app
        mocking? ? mock_app : api
      end

      def self.api(host = (ENV['REDIS_HOST'] || 'localhost' ), port = (ENV['REDIS_PORT'] || 6379).to_i)
        Api.new(host, port)
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

require 'ey_tea/server/ext/em-redis'

require 'ey_tea/server/pubsub_redis'

require 'ey_tea/server/api'

require 'ey_tea/server/deferrable_body'
require 'ey_tea/server/mock_thin'
