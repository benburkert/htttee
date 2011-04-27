require 'thin'
require 'yajl'
require 'sinatra/base'
require 'em-redis'

EM.epoll

module EY
  module Tea
    module Server

      def self.app
        mocking? ? mock_app : rack_app
      end

      def self.api(host = (ENV['REDIS_HOST'] || 'localhost' ), port = (ENV['REDIS_PORT'] || 6379).to_i)
        Api.new(host, port)
      end

      def self.rack_app
        Rack::Builder.app do |builder|
          builder.use AsyncFixer
          builder.use Dechunker
          builder.run Server.api
        end
      end

      def self.mock_app
        Rack::Builder.app do |builder|
          builder.use Mock::ThinMuxer
          builder.use Mock::EchoUri
          builder.run Server.rack_app
        end
      end

      def self.mock!
        require 'ey_tea/server/mock'
        @mocking = true

        @mock_uri = Mock.boot_forking_server
      end

      def self.reset!
        raise "Can't reset in non-mocked mode." unless mocking?

        EM.run do
          EM::Protocols::Redis.connect.flush_all do
            EM.stop
          end
        end
      end

      def self.mocking?
        @mocking
      end

      def self.mock_uri
        raise "Not in mock mode!" unless mocking?
        @mock_uri
      end
    end
  end
end

require 'ey_tea/server/ext/em-redis'
require 'ey_tea/server/ext/thin'

require 'ey_tea/server/pubsub_redis'

require 'ey_tea/server/api'
require 'ey_tea/server/chunked_body'

require 'ey_tea/server/middleware/async_fixer'
require 'ey_tea/server/middleware/dechunker'
