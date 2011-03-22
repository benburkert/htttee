# https://gist.github.com/352068
#
# Incomplete evented Redis implementation specifically made for
# the new PubSub features in Redis.
class PubSubRedis < EM::Connection
  CRLF = "\r\n"

  def self.connect(host = (ENV['REDIS_HOST'] || 'localhost' ), port = (ENV['REDIS_PORT'] || 6379).to_i)
    EM.connect host, port, self
  end

  def post_init
    @buffer = ''
    @blocks = {}
  end

  def subscribe(*channels, &blk)
    channels.each { |c| @blocks[c.to_s] = blk }
    call_command('subscribe', *channels)
  end

  def publish(channel, msg)
    call_command('publish', channel, msg)
  end

  def unsubscribe
    call_command('unsubscribe')
  end

  def receive_data(data)
    debugger
    begin
      read_response(data) do |parts|
        ret
        if parts.is_a?(Array)
          ret = @blocks[parts[1]].call(parts)
          close_connection if ret === false
        end
      end
    end
  end

  private
  def read_response(buffer)
    @buffer << buffer

    if terminated = (buffer[-2, 2] == CRLF)
      lines, @buffer = @buffer.split(CRLF), ''
    else
      lines = @buffer.split(CRLF)
      @buffer = lines.pop
    end

    until lines.empty?
      line = lines.shift
      type, data = line[0], line[1..-1]

      case type
      when ':'
        yield data.to_i
      when '*'
        size = data.to_i
        parts = []
        do
          part = read_object(lines)
          parts << part unless part.nil?
        end
        if lines.size < size
          @buffer = ([line] + lines).join(CRLF)
          @buffer << CRLF if terminated
        else
          yield read_object(lines.shift(size))
        end
      else
        debugger
        raise "unsupported response type"
      end
    end
  end

  def read_object(lines)
    debugger
    parts = []

    until lines.empty?
      line = lines.shift
      type, data = line[0], line[1..-1]

      case type
      when ':' # integer
        parts << data.to_i
      when '$'
        size = data.to_i
        value = lines.shift
        until value.size == size
          value << CRLF << lines.shift
        end

        parts << value
      else
        raise "read for object of type #{type} not implemented"
      end
    end

    parts
  end

  # only support multi-bulk
  def call_command(*args)
    command = "*#{args.size}\r\n"
    args.each { |a|
      command << "$#{a.to_s.size}\r\n"
      command << a.to_s
      command << "\r\n"
    }
    send_data command
  end
end
