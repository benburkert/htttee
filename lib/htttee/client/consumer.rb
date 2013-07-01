module HTTTee
  module Client
    class Consumer < Rack::Client::Base
      def initialize(options = {})
        @base_uri = URI.parse(options.fetch(:endpoint, 'http://localhost:3000/'))
        inner_app = options.fetch(:app, Rack::Client::Handler::NetHTTP.new)

        super(inner_app)
      end

      def up(io, uuid, content_type = 'text/plain')
        headers = {
          'Content-Type'      => content_type,
          'Transfer-Encoding' => 'chunked',
          'Connection'        => 'Keep-Alive',
        }

        post("/#{uuid}", headers, io)
      end

      def down(uuid)
        get("/#{uuid}") do |status, headers, response_body|
          response_body.each do |chunk|
            yield chunk
          end
        end
      end

      def build_env(request_method, url, headers = {}, body = nil)
        uri = @base_uri.nil? ? URI.parse(url) : @base_uri + url

        env = super(request_method, uri.to_s, headers, body)

        env['HTTP_HOST']       ||= http_host_for(uri)
        env['HTTP_USER_AGENT'] ||= http_user_agent

        env
      end

      def http_host_for(uri)
        if uri.to_s.include?(":#{uri.port}")
          [uri.host, uri.port].join(':')
        else
          uri.host
        end
      end

      def http_user_agent
        "htttee (rack-client #{Rack::Client::VERSION} (app: #{@app.class}))"
      end
    end
  end
end
