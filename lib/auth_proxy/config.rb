class AuthProxy::Config
  attr_accessor :app_domain
  attr_accessor :cookie_domain
  attr_accessor :providers
  attr_accessor :ssl
  attr_accessor :views_path

  def initialize
    self.providers = {}
  end

  def register(provider, display_name:, app_id:, app_secret:, options: {}, validator: nil)
    options[:callback_path] ||= "/auth/#{provider}/callback"
    providers[provider.to_s] = {
      provider: provider,
      display_name: display_name,
      app_id: app_id,
      app_secret: app_secret,
      validator: validator,
      options: options
    }
  end
end
