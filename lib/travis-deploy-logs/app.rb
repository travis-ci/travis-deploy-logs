require "sinatra/base"
require 'rack/utils'
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
        basic_username = TravisDeployLogs.config.basic_username
        basic_password = TravisDeployLogs.config.basic_password
        Rack::Utils.secure_compare(username, basic_username) && Rack::Utils.secure_compare(password, basic_password)
      end
    end

    get "/heroku/:env/:app/:id" do
      unless VALID_ENVIRONMENTS.include?(params[:env])
        halt 400, "Unknown environment"
      end

      env = params[:env].gsub("-", "_")
      app = params[:app]

      heroku_org = if app =~ /\Apro-/ || env =~ /\Acom/
                     TravisDeployLogs.config.heroku_orgs["com"]
                   else
                     TravisDeployLogs.config.heroku_orgs["org"]
                   end

      heroku_app = TravisDeployLogs.config.heroku_apps[env][app]

      if heroku_app.nil?
        halt 404, "Unknown app"
      end

      redirect "https://dashboard.heroku.com/orgs/#{heroku_org}/apps/#{heroku_app}/activity/builds/#{params[:id]}"
    end
  end
end
