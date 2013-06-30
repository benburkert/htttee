require 'rack/mux'

module HTTTee
  module Server
    module Mock

      def self.boot_forking_server
        o,i = IO.pipe

        if pid = fork
          at_exit { Process.kill(:SIGTERM, pid) }

          i.close
          URI.parse(o.read)
        else
          o.close
          process_child(i)
        end
      end

      def self.process_child(i)
        EM.run do
          client = Rack::Client.new { run HTTTee::Server.mock_app }

          uri = client.get("/mux-uri").body
          i << uri
          i.close
        end

        exit
      end

      class ThinMuxer
        def initialize(app)
          @app = Rack::Mux.new(async_safe(app), thin_options)
        end

        def call(env)
          @app.call(env)
        end

        def async_safe(app)
          AsyncFixer.new(app)
        end

        def thin_options
          { :server => Thin, :environment => 'none' }
        end
      end

      class EchoUri

        def initialize(app)
          @app = app
        end

        def call(env)
          if env['PATH_INFO'] == '/mux-uri'
            [200, {'Content-Type' => 'text/plain'}, [env['X-Mux-Uri']]]
          else
            @app.call(env)
          end
        end
      end
    end
  end
end
