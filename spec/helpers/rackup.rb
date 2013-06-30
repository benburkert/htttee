module HTTTeeHelpers
  class ThinMuxer
    def initialize(app)
      @app = Rack::Mux.new(thin_options)
    end

    def call(env)
      @app.call(env)
    end

    def thin_options
      { :server => Thin }
    end
  end
end
