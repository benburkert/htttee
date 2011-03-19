module EY
  module Tea
    class MockGoliath
      def initialize(app, api)
        @app, @api = app, api
      end

      def call(env)
        env['rack.logger'] ||= Logger.new($stdout)

        goliath_env = Goliath::Env.new.merge(env)

        # save the fiber for the block
        fiber = Fiber.current

        goliath_env[Goliath::Constants::ASYNC_CALLBACK] = proc do |tuple|
          # send the tuple back to be returned
          fiber.resume tuple
        end

        @app.call(goliath_env)

        # yield and save the stack
        return Fiber.yield
      end
    end
  end
end
