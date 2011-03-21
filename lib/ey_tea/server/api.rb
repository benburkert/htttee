module EY
  module Tea
    module Server
      class Api < Sinatra::Base
        STREAMING, FIN = ?0, ?1
        SUBSCRIBE, UNSUBSCRIBE, MESSAGE = 'SUBSCRIBE', 'UNSUBSCRIBE', 'MESSAGE'

        AsyncResponse = [-1, {}, []].freeze

        attr_accessor :redis, :pubsub, :subscribe_callback

        def initialize(redis, pubsub)
          super()
          @redis, @pubsub = redis, pubsub
          @subscribe_callback = Hash.new {|h,k| h[k] = [] }
        end

        post '/:uuid' do |uuid|
          rack_env, body = env, DeferrableBody.new

          redis.set(state_key(uuid), STREAMING)

          rack_input(rack_env).each do |chunk|
            unless chunk.empty?
              redis.append(data_key(uuid), chunk)
              publish(channel(uuid), STREAMING, chunk) do |*a|
                debugger
                a
              end
            end
          end

          rack_input(rack_env).callback do
            async_callback(rack_env).call [204, {}, body]

            redis.set(state_key(uuid), FIN) do
              publish(channel(uuid), FIN) do |*a|
                debugger
                a
              end
              body.succeed
            end
          end

          rack_input(rack_env).errback do |error|
            async_callback(rack_env).call [500, {}, body]

            body.call [error.inspect]
            body.succeed
          end

          AsyncResponse
        end

        get '/:uuid' do |uuid|
          rack_env, body = env, DeferrableBody.new

          redis.get state_key(uuid) do |state|
            case state
            when NilClass
              rack_env['async.callback'].call [404, {}, body]

              body.succeed
            when STREAMING
              rack_env['async.callback'].call [200, {}, body]

              redis.multi_get state_key(uuid), data_key(uuid) do |state, data|
                body.call [data] unless data.nil? || data.empty?
                body.succeed if state == FIN
              end

              subscribe channel(uuid) do |type, message, *extra|
                case type
                when FIN then body.succeed
                else
                  debugger
                  type
                end
              end
            when FIN
              rack_env['async.callback'].call [200, {}, body]

              redis.get data_key(uuid) do |data|
                body.call [data] unless data.nil?
                body.succeed
              end
            end
          end

          AsyncResponse
        end

        helpers do
          def data_key(uuid)
            "#{uuid}:data"
          end

          def state_key(uuid)
            "#{uuid}:state"
          end

          def channel(uuid)
            uuid
          end

          def rack_input(rack_env)
            rack_env['rack.input']
          end

          def async_callback(rack_env)
            rack_env['async.callback']
          end

          def publish(channel, *data)
            redis.publish channel, Yajl::Encoder.encode(data)
          end

          def subscribe(channel, &block)
            pubsub.subscribe channel do |type, chan, data|
              block.call(*Yajl::Parser.parse(data)) if type.upcase == MESSAGE && channel == chan
            end
          end
        end
      end
    end
  end
end
