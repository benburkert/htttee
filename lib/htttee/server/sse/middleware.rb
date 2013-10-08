module HTTTee
  module Server
    module SSE
      class Middleware

        SHELL_HEADERS = {
          'Content-Type' => 'text/html',
          'Connection'   => 'keep-alive',
        }

        WRAPPER_HEADERS = {
          'Content-Type'  => 'text/event-stream',
          'Cache-Control' => 'no-cache',
          'Connection'    => 'close',
        }

        def initialize(app)
          @app = app
        end

        def call(env)
          if sse_request?(env)
            wrap(env)
          elsif sse_supported?(env)
            return sse_shell
          end

          @app.call(env)
        end

        def wrap(env)
          env['rack.response_body'] = SSE::Body.new(env['rack.response_body'])

          cb = env['async.callback']

          env['async.callback'] = lambda do |(status, headers, body)|
            cb.call([status, headers.merge(WRAPPER_HEADERS), body])
          end
        end

        def sse_request?(env)
          env['HTTP_ACCEPT'] == 'text/event-stream'
        end

        def sse_supported?(env)
          env['HTTP_USER_AGENT'].to_s =~ /WebKit/ &&
            env['HTTP_ACCEPT'] =~ %r{text/html}
        end

        def sse_shell
          [200, SHELL_HEADERS, [<<-HTML]]
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.10.1/jquery.min.js"></script>
</head>
<body><pre><code></code></pre>
  <script>
    var source = new EventSource(window.location.pathname);
    var body = $("html,body");
    var cursor = $("pre code")[0];
    var resetLine = false;

    function append(data) {
      if(resetLine == true) {
        cursor.innerHTML = data;
      } else {
        cursor.innerHTML += data;
      }

      resetLine = false;
    }

    source.onmessage = function(e) {
      append(e.data);
    };

    source.onerror = function(e) {
      console.log(e);
    };

    source.addEventListener('ctrl', function(e) {
      if(e.data == 'newline') {
        append("\\n");
        cursor = $("<code></code>").insertAfter(cursor)[0];
      } else if(e.data == 'crlf' || e.data == 'carriage-return') {
        resetLine = true;
      } else if(e.data == 'eof') {
        source.close();
      } else {
        console.log(e);
      }
    }, false);

    window.setInterval(function(){
      window.scrollTo(0, document.body.scrollHeight);
    }, 100);

  </script>
</body>
</html>
          HTML
        end
      end
    end
  end
end
