module HTTTee
  module Server
    class Api
      STREAMING, FIN = ?0, ?1
      SUBSCRIBE, UNSUBSCRIBE, MESSAGE = 'SUBSCRIBE', 'UNSUBSCRIBE', 'MESSAGE'

      AsyncResponse = [-1, {}, []].freeze

      attr_accessor :redis

      def initialize(host, port)
        @host, @port = host, port
      end

      def call(env)
        uuid = env['PATH_INFO'].sub(/^\//, '')
        body = env['rack.response_body']

        case env['REQUEST_METHOD']
        when 'POST' then post(env, uuid, body)
        when 'GET'  then get(env, uuid, body)
        end

        AsyncResponse
      end

      def post(env, uuid, body)
        redis.set(state_key(uuid), STREAMING)

        set_input_callback(env, uuid, body)
        set_input_errback(env, uuid, body)
        set_input_each(env, uuid, body)
      end

      def get(env, uuid, body)
        with_state_for(uuid) do |state|
          case state
          when NilClass   then four_oh_four_response(env, body)
          when STREAMING  then open_stream_response(env, uuid, body)
          when FIN        then closed_stream_response(env, uuid, body)
          end
        end
      end

      def set_input_callback(env, uuid, body)
        rack_input(env).callback do
          async_callback(env).call [204, {}, body]

          redis.set(state_key(uuid), FIN) do
            finish(channel(uuid))
            body.succeed
          end
        end
      end

      def set_input_errback(env, uuid, body)
        rack_input(env).errback do |error|
          async_callback(env).call [500, {}, body]

          body.call [error.inspect]
          body.succeed
        end
      end

      def set_input_each(env, uuid, body)
        rack_input(env).each do |chunk|
          unless chunk.empty?
            redis.pipeline ['append', data_key(uuid), chunk],
              ['publish', channel(uuid), encode(STREAMING, chunk)]
          end
        end
      end

      def four_oh_four_response(env, body)
        env['async.callback'].call [404, {'Transfer-Encoding' => 'chunked'}, body]

        body.succeed
      end

      def open_stream_response(env, uuid, body)
        start_response(env, body)
        stream_data_to(body, data_key(uuid)) do
          with_state_for(uuid) do |state|
            if state == FIN
              body.succeed
            else
              subscribe_and_stream(env, uuid, body)
            end
          end
        end
      end

      def closed_stream_response(env, uuid, body)
        start_response(env, body)
        stream_data_to(body, data_key(uuid)) do
          body.succeed
        end
      end

      def stream_data_to(body, key, offset = 0, chunk_size = 1024, &block)
        redis.substr(key, offset, offset + chunk_size) do |chunk|
          if chunk.nil? || chunk.empty?
            yield
          else
            body.call [chunk]
            stream_data_to(body, key, offset + chunk.size, chunk_size, &block)
          end
        end
      end

      def respond_with(env, body, data)
        start_response(env, body, data)
        body.succeed
      end

      def start_response(env, body, data = nil)
        env['async.callback'].call [200, {'Transfer-Encoding' => 'chunked', 'Content-Type' => 'text/plain'}, body]

        body.call [data] unless data.nil? || data.empty?
      end

      def subscribe_and_stream(env, uuid, body)
        subscribe channel(uuid) do |type, message, *extra|
          case type
            #when SUBSCRIBE then start_response(env, body, data)
          when FIN       then body.succeed
          when STREAMING then body.call [message]
          end
        end
      end

      def with_state_for(uuid, &block)
        redis.get(state_key(uuid), &block)
      end

      def with_state_and_data_for(uuid, &block)
        redis.multi_get(state_key(uuid), data_key(uuid), &block)
      end

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
        redis.publish channel, encode(STREAMING, data)
      end

      def finish(channel)
        redis.publish channel, encode(FIN)
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
            ''
          end
        end
      end

      def pubsub
        EM::Protocols::PubSubRedis.connect(@host, @port)
      end

      def redis
        @@redis ||= EM::Protocols::Redis.connect(@host, @port)
      end

      def encode(*parts)
        Yajl::Encoder.encode(parts)
      end
    end
  end
end
