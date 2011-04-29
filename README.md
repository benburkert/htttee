# htttee - unix's tee-as-a-service


## What is 'tee'?

    $ man tee
    NAME
         tee -- pipe fitting
    DESCRIPTION
         The tee utility copies standard input to standard output, making a copy in zero or more files.  The output is unbuffered.

It's very handy for piping the output of a script to a file and to STDOUT simultaneously.

## What is 'htttee'?

Instead of piping to a file, `htttee` pipes to a web service. Consumers can then stream the
piped output via the `htttee` command line. Alternately, the streamed output could be viewed
within a browser.

That is, a streaming output locked within a server can be made accessible to a console
or browser via `htttee`.

## Usage

In one terminal:

    ruby -e "1.upto(100) {|i| puts i; \$stdout.flush; sleep(i/100.0)}" | 
      htttee -e http://localhost:3000 -u SOMEUNIQUESTRING

In another terminal:

    curl http://htttee.engineyard.com/SOMEUNIQUESTRING

Or to see the chunked information:

    $ telnet localhost 3000

Then enter:

    GET /1234 HTTP/1.1
    Host: localhost

You will then see a flow of integers being chunked preceded by the size of the chunks. Here is the 
final few numbers chunked through:

    3
    98
    
    3
    99
    
    4
    100
    
    0
    
    Connection closed by foreign host.


## Running the server

    git clone git://github.com/benburkert/htttee.git
    cd htttee
    bundle
    thin start

## Development

To pull down the repository and run the test suite:

    git clone git://github.com/benburkert/htttee.git
    cd htttee
    bundle
    rake

To install the gem locally from source:

    rake install

To release the gem:

    rake release

## License

Copyright (c) 2011 Ben Burkert, ben@benburkert.com

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.