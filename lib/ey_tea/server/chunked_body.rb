module EY
  module Tea
    module Server
      class ChunkedBody < Thin::DeferrableBody
        def call(body)
          body.each do |fragment|
            @body_callback.call(chunk(fragment))
          end
        end

        def succeed(*a)
          @body_callback.call("0\r\n\r\n")
          super
        end

        def chunk(fragment)
          "#{fragment.size.to_s(16)}\r\n#{fragment}\r\n"
        end
      end
    end
  end
end
