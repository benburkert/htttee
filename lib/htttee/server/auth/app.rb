module HTTTee
  module Server
    module Auth
      class App < Sinatra::Base
        enable :sessions

        set :github_options, {
          :scopes    => "user",
          :secret    => ENV['GITHUB_CLIENT_SECRET'],
          :client_id => ENV['GITHUB_CLIENT_ID'],
        }

        register Sinatra::Auth::Github

        get '*' do
          authenticate!
          pass
        end

      end
    end
  end
end
