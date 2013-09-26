require 'spec_helper'

describe HTTTee::Client do
  subject { @client }

  def new_client
    HTTTee::Client.new(:endpoint => HTTTee::Server.mock_uri.to_s)
  end

  def run(thread)
    if RUBY_VERSION =~ /^2\./
      return Thread.pass if thread == Thread.main
    end

    thread.join(0.1) if thread.alive?
  end

  it "can stream an IO" do
    uuid = rand(10_000).to_s
    o,i = IO.pipe
    i << "Hello, World!"
    i.close

    new_client.up(o, uuid)

    body = ''
    new_client.down(uuid) do |chunk|
      body << chunk
    end
    body.should == 'Hello, World!'
  end

  it "can stream out before the incoming stream has finished." do
    scheduler = Thread.current
    uuid = rand(10_000).to_s
    o, i = IO.pipe
    i << 'Hello, '

    up_thread = Thread.new(new_client, o) do |client, reader|
      client.up(reader, uuid)
    end

    client_called = false
    down_thread = Thread.new(new_client, i, scheduler) do |client, writer|
      run scheduler
      client.down(uuid) do |chunk|
        if chunk == 'Hello, '
          client_called = true
          writer << 'World!'
          writer.close
          run scheduler
        end
      end
    end

    client_called.should be_false

    run up_thread
    run down_thread
    run up_thread
    run down_thread

    client_called.should be_true
  end

  it "can accept a stream containing CRLFs." do
    scheduler = Thread.current
    uuid = rand(10_000).to_s
    o, i = IO.pipe
    i << "Hello, \r\n\r\nthere"

    up_thread = Thread.new(new_client, o) do |client, reader|
      run scheduler
      client.up(reader, uuid)
    end

    client_called = false

    down_thread = Thread.new(new_client, i, scheduler) do |client, writer|
      run scheduler
      client.down(uuid) do |chunk|
        if chunk == "Hello, \r\n\r\nthere"
          client_called = true
          writer.close
          run scheduler
        end
      end
    end

    client_called.should be_false

    run up_thread
    run down_thread
    run up_thread
    run down_thread

    client_called.should be_true
  end

  it "streams already recieved data on an open stream to peers." do
    scheduler = Thread.current
    uuid = rand(10_000).to_s
    o, i = IO.pipe

    i << 'Existing Data'

    up_thread = Thread.new(subject, o) do |client, reader|
      run scheduler
      client.up(reader, uuid)
    end

    down_thread = Thread.new(new_client) do |client|
      run scheduler
      Thread.current[:data] = ''

      client.down(uuid) do |chunk|
        Thread.current[:data] << chunk
        run scheduler
      end
    end

    run up_thread
    run down_thread

    down_thread[:data] == 'Existing Data'
  end

  it "streams the same data to all peers." do
    scheduler = Thread.current
    uuid = rand(10_000).to_s
    o, i = IO.pipe

    up_thread = Thread.new(new_client, o) do |client, reader|
      client.up(reader, uuid)
    end

    run up_thread

    down_threads = Array.new(5, new_client).map do |c|
      Thread.new(c) do |client|
        Thread.current[:chunks] = []
        run scheduler

        client.down(uuid) do |chunk|
          Thread.current[:chunks] << chunk
          run scheduler
        end
      end
    end

    i << "First Part"

    down_threads.each {|t| run t }
    down_threads.each {|t| t[:chunks].should == ['First Part'] }

    i << "Second Part"

    down_threads.each {|t| run t }
    down_threads.each {|t| t[:chunks].should == ['First Part', 'Second Part'] }

    i << "Third Part"

    down_threads.each {|t| run t }
    down_threads.each {|t| t[:chunks].should == ['First Part', 'Second Part', 'Third Part'] }

    i.close
  end

  it "gets the SSE setup page if the client supports SSE." do
    scheduler = Thread.current
    uuid = rand(10_000).to_s
    o, i = IO.pipe
    i << 'Ignore Me!'
    i.close

    up_thread = Thread.new(new_client, o) do |client, reader|
      client.up(reader, uuid)
    end

    run up_thread

    client = Rack::Client.new(HTTTee::Server.mock_uri.to_s)

    response = client.get(uuid, 'User-Agent' => 'OctoWebKit', 'Accept' => 'text/html')

    response.headers['Content-Type'].should == 'text/html'
    response.body =~ /new EventSource/
  end

  it "gets the SSE stream response when making an SSE request." do
    scheduler = Thread.current
    uuid = rand(10_000).to_s
    o, i = IO.pipe
    i << "Don't Ignore Me!\nPlease!"
    i.close

    up_thread = Thread.new(new_client, o) do |client, reader|
      client.up(reader, uuid)
    end

    run up_thread

    client = Rack::Client.new(HTTTee::Server.mock_uri.to_s)

    response = client.get(uuid, 'User-Agent' => 'OctoWebKit', 'Accept' => 'text/event-stream')

    response.headers['Content-Type'].should == 'text/event-stream'

    response.body.should == <<-BODY
event: message
data: Don't Ignore Me!

event: ctrl
data: newline

event: message
data: Please!

event: ctrl
data: eof

    BODY
  end

end
