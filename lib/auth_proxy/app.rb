require "sinatra/base"
require "json"

class AuthProxy::App < Sinatra::Base
  if ENV["RACK_ENV"] == "development"
    begin
      require "better_errors"
      use BetterErrors::Middleware
      BetterErrors.application_root = __dir__
    rescue
    end

    set :show_exceptions, :after_handler
  end

  get "/auth/:provider/callback" do
    AuthProxy.validate_auth_request(params[:provider], request)
    oauth = request.env["omniauth.auth"]
    session[:authenticated] = "true"
    session[:user_name] = oauth.info.name
    session[:user_email] = oauth.info.email
    session[:user_id] = oauth.uid
    session[:user_provider] = params[:provider]
    session[:user_token] = oauth.credentials.token
    redirect session[:return_to] ? session.delete(:return_to) : "/"
  end

  get "/auth/failure" do
    session[:alert] = params[:message]
    redirect "/login"
  end

  get "/auth/try" do
    if session[:authenticated] == "true"
      auth_proxy_headers = {}
      %i{user_name user_email user_id user_provider user_token}.each do |key|
        auth_proxy_headers["x_auth_proxy_#{key}".gsub("_", "-")] = session[key]
      end
      headers auth_proxy_headers
      halt 200
    else
      halt 401
    end
  end

  get "/login" do
    session[:return_to] = params[:return_to] if params[:return_to]
    if session[:authenticated] == "true"
      redirect session[:return_to] ? session.delete(:return_to) : "/"
    else
      erb :login, layout: :layout
    end
  end

  get "/logout" do
    session.clear
    redirect request.referer || "/login"
  end

  get "/" do
    if session[:authenticated] == "true"
      erb "You're authenticated. Now navigate to your app"
    else
      redirect "/login"
    end
  end

  error AuthProxy::ProviderValidationError do
    session[:alert] = "Could not validate your credentials"
    redirect "/login"
  end
end
