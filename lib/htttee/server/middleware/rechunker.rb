module HTTTee
  module Server
    class Rechunker
      def initialize(app)
        @app = app
      end

      def call(env)
        env['rack.response_body'] = ChunkedBody.new

        @app.call(env)
      end
    end
  end
end
