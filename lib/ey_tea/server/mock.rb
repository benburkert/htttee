module EY
  module Tea
    class MockGoliath
      def initialize(app, api = Goliath::API.last_api)
        @app, @api = app, api
      end

      def call(env)
        env['rack.logger'] ||= Logger.new($stdout)

        MockConnection.new(@app, @api, env).yield
      end
    end

    class MockConnection
      attr_accessor :app, :api, :env

      def initialize(app, api, env)
        @app, @api, @env = app, api, Goliath::Env.new.merge(env)
      end

      def yield
        @fiber = Fiber.current

        @env[Goliath::Constants::ASYNC_CALLBACK] = method(:callback)
        @app.call(@env)


        Fiber.yield while @tuple.nil?

        @tuple
      end

      def callback(tuple)
        @tuple = tuple

        @fiber.transfer
      end
    end
  end
end
