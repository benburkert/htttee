module Net
  class HTTP
    class Post
      def send_request_with_body_stream(sock, ver, path, f)
        unless content_length() or chunked?
          raise ArgumentError,
            "Content-Length not given and Transfer-Encoding is not `chunked'"
        end
        supply_default_content_type
        write_header sock, ver, path
        if chunked?
          begin
            while s = f.readpartial(1024)
              sock.write(sprintf("%x\r\n", s.length) << s << "\r\n")
            end
          rescue EOFError
            sock.write "0\r\n\r\n"
          end
        else
          while s = f.read(1024)
            sock.write s
          end
        end
      end
    end
  end
end
