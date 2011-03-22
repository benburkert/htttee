module TeaHelper
  def get(*a, &b)
    subject.get(*a, &step(&b))
  end

  def post(*a, &b)
    subject.post(*a, &step(&b))
  end

  def empty_body
    body = EY::Tea::Server::DeferrableBody.new
    EM.next_tick { body.succeed }
    body
  end

  def step(&b)
    register b
    lambda do |*a|
      finish b, *a
    end
  end

  def register(block)
    steps << block
  end

  def finish(block, *a)
    steps.delete(block)
    block.call(*a)
  end

  def steps
    @steps ||= []
  end

  def run
    EM.run do
      EM::Protocols::Redis.connect.flush_all(&step { yield })
      finish_steps
    end
  end

  def finish_steps
    if steps.empty?
      EM.stop
    else
      EM.next_tick { finish_steps }
    end
  end

  class MultiPartBody < EY::Tea::Server::DeferrableBody
    def add_part
      call [yield]
    end
  end
end
