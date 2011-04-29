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