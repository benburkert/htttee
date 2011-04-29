# htttee - unix's tee-as-a-service


## Usage

In one terminal:

    history | ./bin/htttee -u SOMEUNIQUESTRING

In another terminal:

    curl http://htttee.engineyard.com/SOMEUNIQUESTRING




    history | ./bin/htttee -u history -e http://localhost:3000



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