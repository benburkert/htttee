module EY
  module Tea
    module Server
      class Dechunker
        def initialize(app)
          @app = app
        end

        def call(env)
          env['rack.input'] = ChunkedBody.new(env['rack.input']) if chunked?(env)

          @app.call(env)
        end

        def chunked?(env)
          env['HTTP_TRANSFER_ENCODING'] == 'chunked'
        end

        class ChunkedBody
          extend Forwardable

          CRLF = "\r\n"

          attr_reader :input

          def_delegators :input, :callback, :errback

          def initialize(input)
            @input, @buffer = input, ''
          end

          def each(&blk)
            @input.each do |chunk|
              dechunk(chunk, &blk)
            end
          end

          def dechunk(chunk, &blk)
            @buffer << chunk

            loop do
              return unless @buffer[CRLF]

              string_length, remainder = @buffer.split(CRLF, 2)
              length = string_length.to_i(16)

              if length == 0
                @buffer = ''
                @input.succeed
                return
              elsif remainder.size >= length + 2 # length + CRLF
                data, @buffer = remainder.split(CRLF, 2)
                blk.call(data)
              else
                return
              end
            end
          end
        end
      end
    end
  end
end
