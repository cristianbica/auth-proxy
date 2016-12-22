# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "auth_proxy/version"

Gem::Specification.new do |spec|
  spec.name          = "auth-proxy"
  spec.version       = AuthProxy::VERSION
  spec.authors       = ["Cristian Bica"]
  spec.email         = ["cristian.bica@gmail.com"]

  spec.summary       = "Auth Proxy App"
  spec.description   = "Auth Proxy App (supports user / pass, oauth2)"
  spec.homepage      = "https://github.com/cristianbica/auth-proxy"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra"
  spec.add_dependency "json"
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
end
