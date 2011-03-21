require 'spec_helper'

describe EY::Tea::Server do
  subject { @server_client }

  describe "POST /:uuid" do
    it "accepts single part posts" do
      post('/123', {'Content-Type' => 'text/plain'}, ['Hello World!']) do |status, headers, body|
        status.should == 204

        get('/123') do |status, headers, body|
          status.should == 200

          data = []
          body.each(&step {|chunk| data << chunk })

          body.callback(&step { data.join.should == 'Hello World!' })
        end
      end
    end
  end
end
