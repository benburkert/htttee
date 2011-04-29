module EventMachine
  module Protocols
    class PubSubRedis < EventMachine::Connection
      include Redis

      def subscribe(channel, &block)
        @pubsub_callback = block

        call_command(['subscribe', channel])
      end

      def unsubscribe(channel)
        @pubsub_callback = lambda do |*args|
          close_connection
        end

        call_command(['unsubscribe', channel])
      end

      def dispatch_response(value)
        if @multibulk_n
          @multibulk_values << value
          @multibulk_n -= 1

          if @multibulk_n == 0
            value = @multibulk_values
            @multibulk_n,@multibulk_values = @previous_multibulks.pop
            if @multibulk_n
              dispatch_response(value)
              return
            end
          else
            return
          end
        end

        @pubsub_callback.call(value)
      end

      def self.connect(*args)
        case args.length
        when 0
          options = {}
        when 1
          arg = args.shift
          case arg
          when Hash then options = arg
          when String then options = {:host => arg}
          else raise ArgumentError, 'first argument must be Hash or String'
          end
        when 2
          options = {:host => args[0], :port => args[1]}
        else
          raise ArgumentError, "wrong number of arguments (#{args.length} for 1)"
        end
        options[:host] ||= '127.0.0.1'
        options[:port]   = (options[:port] || 6379).to_i
        EM.connect options[:host], options[:port], self, options
      end

      def initialize(options = {})
        @host           = options[:host]
        @port           = options[:port]
        @db             = (options[:db] || 0).to_i
        @password       = options[:password]
        @logger         = options[:logger]
        @error_callback = lambda do |code|
          err = RedisError.new
          err.code = code
          raise err, "Redis server returned error code: #{code}"
        end

        # These commands should be first
        auth_and_select_db
      end
    end
  end
end
