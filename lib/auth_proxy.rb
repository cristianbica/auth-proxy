require "auth_proxy/version"
require "auth_proxy/config"
require "auth_proxy/errors"
require "auth_proxy/app"

module AuthProxy
  def self.configure(&block)
    yield @config ||= AuthProxy::Config.new
  end

  def self.config
    @config
  end

  configure do |config|
    config.app_domain = ENV["AUTH_PROXY_APP_DOMAIN"]
    config.cookie_domain = ENV["AUTH_PROXY_COOKIE_DOMAIN"]
    config.ssl = false
  end

  def self.root_path
    File.expand_path("../../", __FILE__)
  end

  def self.full_url
    URI::Generic.build(
      scheme: config.ssl ? "https" : "http",
      host: config.app_domain
    ).to_s
  end

  def self.validate_auth_request(provider, request)
    validator = config.providers[provider.to_s][:validator]
    validator.call(request) unless validator.nil?
  end

  def self.app
    Sinatra.new(AuthProxy::App) do
      use Rack::Session::Cookie, key: "rack.session",
                                 domain: "." + AuthProxy.config.cookie_domain,
                                 path: "/",
                                 expire_after: 2592000,
                                 secret: "a-secret"

      set :views, AuthProxy.config.views_path || "#{AuthProxy.root_path}/views"

      if AuthProxy.config.providers.any?
        OmniAuth.config.full_host = AuthProxy.full_url
        OmniAuth.config.failure_raise_out_environments = []
        use OmniAuth::Builder do
          AuthProxy.config.providers.each do |name, p|
            provider p[:provider], p[:app_id], p[:app_secret], p[:options]
          end
        end
      end
    end
  end

end
