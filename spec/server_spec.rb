require 'spec_helper'

describe EY::Tea::Server do
  subject { @server_client }
  let(:uuid) { Time.now.to_f }
  let(:url) { "/#{uuid}" }

  describe "POST /:uuid" do
    it "accepts single part posts" do
      post(url, {'Content-Type' => 'text/plain'}, ['Hello World!']) do |status, headers, body|
        status.should == 204

        get(url) do |status, headers, body|
          status.should == 200

          data = []
          body.each(&step {|chunk| data << chunk })

          body.callback(&step { data.join.should == 'Hello World!' })
        end
      end
    end

    it "accepts multi-part posts" do
      post_body = MultiPartBody.new

      post(url, {'Content-Type' => 'text/plain'}, post_body) do |status, headers, body|
        status.should == 204

        get(url) do |status, headers, body|
          status.should == 200

          data = []

          body.each(&step {|chunk| data << chunk })

          body.callback(&step { data.join.should == "Line 1\nLine 2" })

        end
      end

      post_body.add_part(&step { "Line 1\n" })
      post_body.add_part(&step { "Line 2" })
      post_body.succeed
    end

    it "allows multiple clients to receive the same document" do
      post(url, {'Content-Type' => 'text/plain'}, [Time.now.to_s]) do |status, headers, body|
        status.should == 204

        data1, data2 = [], []

        get(url) do |status, headers, body|
          status.should == 200

          body.each(&step {|chunk| data1 << chunk })

          body.callback(&step do
            get(url) do |status, headers, body|
              status.should == 200

              body.each(&step {|chunk| data2 << chunk })

              body.callback(&step { data1.join.should == data2.join })
            end
          end)
        end
      end
    end

    it "can stream data written before the client connects" do
      post_body = MultiPartBody.new

      post(url, {'Content-Type' => 'text/plain'}, post_body) do |status, headers, body|
        status.should == 204
      end

      post_body.call ["Line 1\n"]

      post_body.add_part(&step do
        get(url) do |status, headers, body|
          status.should == 200

          body.each(&step do |chunk|
            chunk.should == "Line 1\n"
            post_body.succeed
          end)

          body.callback(&step {})
        end

        post_body.succeed

        ""
      end)
    end

    it "can stream data written after the client connects" do
      post_body = MultiPartBody.new

      post(url, {'Content-Type' => 'text/plain'}, post_body) do |status, headers, body|
        status.should == 204
      end

      post_body.add_part(&step do
        get(url) do |status, headers, body|
          status.should == 200
          client_streaming_at = Time.now.to_f
          server_wrote_at = nil

          post_body.add_part(&step do
            Time.now.to_f.to_s
          end)

          body.each(&step do |chunk|
            server_wrote_at = Float(chunk)
            post_body.succeed
          end)

          body.callback(&step { client_streaming_at.should < server_wrote_at })
        end

        ""
      end)
    end
  end
end
