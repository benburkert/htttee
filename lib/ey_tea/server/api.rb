module EY
  module Tea
    module Server
      class Api < Sinatra::Base
        STREAMING, FIN = ?0, ?1
        SUBSCRIBE, UNSUBSCRIBE, MESSAGE = 'SUBSCRIBE', 'UNSUBSCRIBE', 'MESSAGE'

        AsyncResponse = [-1, {}, []].freeze

        attr_accessor :redis

        set :raise_errors, true
        set :show_exceptions, false

        def initialize(host, port)
          super()
          @host, @port = host, port
        end

        post '/:uuid' do |uuid|
          rack_env, body = env, Thin::DeferrableBody.new

          redis.set(state_key(uuid), STREAMING)

          rack_input(rack_env).callback do
            async_callback(rack_env).call [204, {}, body]

            redis.set(state_key(uuid), FIN) do
              finish(channel(uuid))
              body.succeed
            end
          end

          rack_input(rack_env).errback do |error|
            async_callback(rack_env).call [500, {}, body]

            body.call [error.inspect]
            body.succeed
          end

          rack_input(rack_env).each do |chunk|
            unless chunk.empty?
              redis.pipeline(['append', data_key(uuid), chunk], ['publish', channel(uuid), Yajl::Encoder.encode([STREAMING, chunk])])
            end
          end

          AsyncResponse
        end

        get '/:uuid' do |uuid|
          rack_env, body = env, ChunkedBody.new

          redis.get state_key(uuid) do |state|
            case state
            when NilClass
              rack_env['async.callback'].call [404, {}, body]

              body.succeed
            when STREAMING

              redis.multi_get state_key(uuid), data_key(uuid) do |state, data|

                if state == FIN
                  rack_env['async.callback'].call [200, {'Transfer-Encoding' => 'chunked'}, body]
                  body.call [data] unless data.nil? || data.empty?
                  body.succeed
                else
                  subscribe channel(uuid) do |type, message, *extra|
                    case type
                    when SUBSCRIBE  then
                      rack_env['async.callback'].call [200, {'Transfer-Encoding' => 'chunked'}, body]
                      body.call [data] unless data.nil? || data.empty?
                    when FIN        then body.succeed
                    when STREAMING  then body.call [message]
                    end
                  end
                end
              end

            when FIN
              rack_env['async.callback'].call [200, {'Transfer-Encoding' => 'chunked'}, body]

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

          def publish(channel, data)
            redis.publish channel, Yajl::Encoder.encode([STREAMING, data])
          end

          def finish(channel)
            redis.publish channel, Yajl::Encoder.encode([FIN])
          end

          def subscribe(channel, &block)
            conn = pubsub
            conn.subscribe channel do |type, chan, data|
              case type.upcase
              when SUBSCRIBE then block.call(SUBSCRIBE, chan)
              when MESSAGE
                state, data = Yajl::Parser.parse(data)
                case state
                when STREAMING  then block.call(STREAMING, data)
                when FIN
                  conn.unsubscribe channel
                  block.call(FIN, data)
                end
              else
                debugger
                ''
              end
            end
          end

          def pubsub
            EM::Protocols::PubSubRedis.connect(@host, @port)
          end

          def redis
            @redis ||= EM::Protocols::Redis.connect(@host, @port)
          end
        end
      end
    end
  end
end
