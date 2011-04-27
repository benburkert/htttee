
module EY
  module Tea
    module Server
      class AsyncFixer
        def initialize(app)
          @app = app
        end

        def call(env)
          tuple = @app.call(env)

          if tuple.first == -1
            Thin::Connection::AsyncResponse
          else
            tuple
          end
        end
      end
    end
  end
end
