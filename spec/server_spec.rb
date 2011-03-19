require 'spec_helper'

describe EY::Tea::Server do
  subject { @server_client }

  describe "POST /:uuid" do
    it "accepts single part posts" do
      subject.post('/123', {'Content-Type' => 'text/plain'}, 'Hello World!')
      subject.get('/123').body.should == 'Hello World!'
    end
  end
end
