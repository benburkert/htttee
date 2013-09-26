module Thin
  class DeferredRequest < Request
    CRLF = "\r\n"

    def parse(data)
      if @parser.finished?  # Header finished, can only be some more body
        body << data
      else                  # Parse more header using the super parser
        @data << data
        raise InvalidRequest, 'Header longer than allowed' if @data.size > MAX_HEADER

        @nparsed = @parser.execute(@env, @data, @nparsed)

        if @parser.finished?
          return super(data) unless @env['HTTP_TRANSFER_ENCODING'] == 'chunked'

          initial_body = @data.partition(CRLF * 2)[2] || ''

          @body = DeferrableBody.new(initial_body)

          return true # trigger the rack call chain
        end
      end

      return false  # only trigger the rack call chain once, just after the headers are parsed
    end

    def env
      super.merge(RACK_INPUT => body)
    end
  end
end
