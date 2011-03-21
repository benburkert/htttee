module EY
  module Tea
    module Server
      class DeferrableBody
        include EventMachine::Deferrable

        def call(body)
          body.each do |chunk|
            @body_callback.call(chunk)
          end
        end

        def each(&blk)
          @body_callback = blk
        end
      end
    end
  end
end
