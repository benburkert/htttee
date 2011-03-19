module EY
  module Tea
    class Api < Goliath::API

      def response(env)
        case env['REQUEST_METHOD'].upcase
        when 'GET'  then get(env)
        when 'POST' then post(env)
        end
      end

      def get(env)
        [200, {}, '']
      end

      def post(env)
        [200, {}, '']
      end
    end
  end
end
