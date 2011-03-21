module EY
  module Tea
    module Server
      class Api < Sinatra::Base
        AsyncResponse = [-1, {}, []].freeze

        attr_accessor :redis

        def initialize(redis)
          super()
          @redis = redis
        end

        post '/:uuid' do |uuid|
          body = DeferrableBody.new

          env['rack.input'].each do |chunk|
            redis.append(uuid, chunk)
          end

          env['rack.input'].callback do
            env['async.callback'].call [204, {}, body]

            body.succeed
          end

          env['rack.input'].errback do |error|
            env['async.callback'].call [500, {}, body]

            body.call [error.inspect]
            body.succeed
          end

          AsyncResponse
        end

        get '/:uuid' do |uuid|
          body = DeferrableBody.new

          redis.get uuid do |data|
            if data.nil?
              env['async.callback'].call [404, {}, body]

              body.succeed
            else
              env['async.callback'].call [200, {}, body]

              body.call [data]

              body.succeed
            end
          end

          AsyncResponse
        end
      end
    end
  end
end
