require 'uri'
require 'thin'
require 'yajl'
require 'sinatra/base'
require 'em-redis'
require 'sinatra_auth_github'
require 'rack/ssl'

EM.epoll

module HTTTee
  module Server

    def self.app
      mocking? ? mock_app : rack_app
    end

    def self.api(host = redis_url.host, port = redis_url.port)
      Api.new(host, port)
    end

    def self.redis_url
      return URI.parse(ENV['REDIS_URL']) if ENV['REDIS_URL']

      host = ENV['REDIS_HOST'] || 'localhost'
      port = ENV['REDIS_PORT'] || 6379

      URI.parse("redis://#{host}:#{port}")
    end

    def self.rack_app
      Rack::Builder.app do |builder|
        builder.use Rack::SSL if ENV['SSL']
        builder.use Auth::Middleware
        builder.use AsyncFixer
        builder.use Dechunker
        builder.use Rechunker
        builder.use SSE::Middleware
        builder.run Server.api
      end
    end

    def self.mock_app
      Rack::Builder.app do |builder|
        builder.use Mock::ThinMuxer
        builder.use Mock::EchoUri
        builder.use Rechunker
        builder.run Server.rack_app
      end
    end

    def self.mock!
      require 'htttee/server/mock'
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

require 'htttee/server/ext/em-redis'
require 'htttee/server/ext/thin'

require 'htttee/server/pubsub_redis'

require 'htttee/server/api'
require 'htttee/server/chunked_body'

require 'htttee/server/middleware/async_fixer'
require 'htttee/server/middleware/dechunker'
require 'htttee/server/middleware/rechunker'

require 'htttee/server/auth/app'
require 'htttee/server/auth/middleware'

require 'htttee/server/sse/body'
require 'htttee/server/sse/middleware'
