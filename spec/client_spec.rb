require 'spec_helper'

describe EY::Tea::Client do
  subject { @client }

  def new_client
    EY::Tea::Client.new(:endpoint => EY::Tea::Server.mock_uri.to_s)
  end

  it "can stream an IO" do
    o,i = IO.pipe
    i << "Hello, World!"
    i.close

    subject.up(o, '123abc')

    body = ''
    subject.down('123abc') do |chunk|
      body << chunk
    end
    body.should == 'Hello, World!'
  end

  it "can stream out before the incoming stream has finished." do
    o, i = IO.pipe
    i << 'Hello, '

    threads = []
    threads << Thread.new(subject, o) do |client, reader|
      client.up(reader, '101')
    end

    threads << Thread.new(subject, i) do |client, writer|
      client.down('101') do |chunk|
        if chunk == 'Hello, '
          writer << 'World!'
          writer.close
        end
      end
    end

    Thread.pass while threads.any? {|t| t.alive? }
  end

  it "streams already recieved data on an open stream to peers." do
    uuid = rand(10_000).to_s
    o, i = IO.pipe

    i << 'Existing Data'

    upstream_thread = Thread.new(subject, o) do |client, reader|
      client.up(reader, uuid)
    end

    first_downstream = Thread.new(new_client) do |client|
      Thread.current[:data] = ''

      client.down(uuid) do |chunk|
        Thread.current[:data] << chunk
      end
    end

    first_downstream.run until first_downstream[:data] == 'Existing Data'
  end

  it "streams the same data to all peers." do
    uuid = rand(10_000).to_s
    o, i = IO.pipe

    upstream_thread = Thread.new(subject, o) do |client, reader|
      client.up(reader, uuid)
    end

    downstream_threads = Array.new(5, new_client).map do
      Thread.new(subject) do |client|
        client.down(uuid) do |chunk|
          Thread.current[:current_chunk] = chunk
          Thread.stop
        end
      end
    end

    i << "First Part"

    sleep 5 # pubsub seems to be laggy, WTF?!?

    downstream_threads.each {|t| t.run }

    sleep 0.1 until downstream_threads.all? {|t| t.status == 'sleep' }

    downstream_threads.each {|t| t[:current_chunk].should == 'First Part' }

    i << "Second Part"

    sleep 5

    downstream_threads.each {|t| t.run }

    sleep 0.1 until downstream_threads.all? {|t| t.status == 'sleep' }

    downstream_threads.each {|t| t[:current_chunk].should == 'Second Part' }

    i << "Third Part"

    sleep 5

    downstream_threads.each {|t| t.run }

    sleep 0.1 until downstream_threads.all? {|t| t.status == 'sleep' }

    downstream_threads.each {|t| t[:current_chunk].should == 'Third Part' }

    i.close
  end

end
