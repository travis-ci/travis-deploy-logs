require "sinatra/base"
require "travis/config"

module TravisDeployLogs
  def self.config
    @config ||= Travis::Config.load
  end

  class App < Sinatra::Base
    VALID_ENVIRONMENTS = %w[
      production
      com-production
      org-production
      staging
      com-staging
      org-staging
    ]

    configure :production do
      use Rack::Auth::Basic do |username, password|
        username == TravisDeployLogs.config.basic_username && password == TravisDeployLogs.config.basic_password
      end
    end

    get "/heroku/:env/:app/:id" do
      unless VALID_ENVIRONMENTS.include?(params[:env])
        halt 400, "Unknown environment"
      end

      env = params[:env].gsub("-", "_")
      app = params[:app]

      heroku_app = TravisDeployLogs.config.heroku_apps[env][app]

      if heroku_app.nil?
        halt 404, "Unknown app"
      end

      redirect "https://dashboard-next.heroku.com/apps/#{heroku_app}/activity/builds/#{params[:id]}"
    end
  end
end
