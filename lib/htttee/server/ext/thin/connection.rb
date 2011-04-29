module Thin
  class Connection
    def post_init
      @request  = DeferredRequest.new
      @response = DeferredResponse.new
    end
  end
end
