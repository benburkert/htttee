module EY
  module Tea
    class Api
      def initialize(get = Get.new, post = Post.new)
        @get, @post = get, post
      end

      def call(env)
        case env['REQUEST_METHOD'].upcase
        when 'GET'  then @get.call(env)
        when 'POST' then @post.call(env)
        end
      end

      class Get < Goliath::API
      end

      class Post < Goliath::API
      end
    end
  end
end
