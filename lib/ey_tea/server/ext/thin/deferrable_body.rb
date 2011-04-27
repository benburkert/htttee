module Thin
  class DeferrableBody
    include EventMachine::Deferrable

    def initialize(initial_body = '')
      @initial_body = initial_body.to_s
    end

    def call(body)
      body.each do |chunk|
        @body_callback.call(chunk)
      end
    end

    def <<(*chunks)
      call(chunks)
    end

    def each(&blk)
      blk.call(@initial_body) unless @initial_body.empty?
      @body_callback = blk
    end
  end
end
