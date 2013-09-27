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

        set :github_org, ENV['GITHUB_ORG']

        register Sinatra::Auth::Github

        get '*' do
          if settings.github_org?
            github_organization_authenticate!(settings.github_org)
          else
            authenticate!
          end

          pass
        end

      end
    end
  end
end
