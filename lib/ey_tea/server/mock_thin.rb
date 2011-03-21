module EY
  module Tea
    module Server
      class MockThin
        def initialize(app)
          @app = app
        end

        def call(env, &block)
          if env['REQUEST_METHOD'] == 'POST' && !env['rack.input'].is_a?(DeferrableBody)
            rack_input = DeferrableBody.new

            env['rack.input'].each do |chunk|
              EM.next_tick { rack_input.call [chunk] }
            end

            EM.next_tick { rack_input.succeed }

            env['rack.input'] = rack_input
          end

          env['async.callback'] = block if block_given?

          @app.call(env)
        end
      end
    end
  end
end
