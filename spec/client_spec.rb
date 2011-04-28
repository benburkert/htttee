require 'spec_helper'

describe EY::Tea::Client do
  subject { @client }

  def new_client
    EY::Tea::Client.new(:endpoint => EY::Tea::Server.mock_uri.to_s)
  end

  def run(thread)
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
      run scheduler
      client.up(reader, uuid)
    end

    down_thread = Thread.new(new_client, i, scheduler) do |client, writer|
      run scheduler
      client.down(uuid) do |chunk|
        if chunk == 'Hello, '
          writer << 'World!'
          writer.close
          run scheduler
        end
      end
    end

    run up_thread
    run down_thread
    run up_thread
    run down_thread
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

end
