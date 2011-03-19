module EY
  module Tea
    class Api < Goliath::API

      attr_accessor :redis

      def initialize(redis)
        @redis = redis
      end

      def response(env)
        case env['REQUEST_METHOD'].upcase
        when 'GET'  then get(env)
        when 'POST' then post(env)
        end
      end

      def get(env)
        uuid = env['PATH_INFO'].gsub(%r{^/}, '')

        result = redis.get(uuid)

        [200, {}, result]
      end

      def post(env)
        uuid = env['PATH_INFO'].gsub(%r{^/}, '')

        result = redis.set(uuid, env['rack.input'].read)

        [200, {}, '']
      end

    end
  end
end
