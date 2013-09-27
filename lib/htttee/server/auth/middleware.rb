module HTTTee
  module Server
    module Auth
      class Middleware

        def self.new(app)
          oauth_configured? ? Auth::App.new(app) : app
        end

        def self.oauth_configured?
          ENV['GITHUB_CLIENT_ID'] && ENV['GITHUB_CLIENT_SECRET']
        end

      end
    end
  end
end
