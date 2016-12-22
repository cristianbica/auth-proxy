# Auth::Proxy

External auth for your web services.

IMPORTANT: This is still under development and untested

## Usage

Create a directorry for your auth-proxy app.

Create a Gemfile and add the auth-proxy gem and any omniauth gems you want to use:

```ruby
gem "auth-proxy"
gem "omniauth-facebook"
gem "omniauth-twitter"
```

And then execute:

    $ bundle install

Create a config.ru file:

```ruby
require "auth-proxy"
require "omniauth-facebook"

AuthProxy.configure do |config|
  config.ssl = true
  config.register :facebook,
    display_name: "Facebook",
    app_id: "ID",
    app_secret: "SECRET"
end

run AuthProxy.app
```

And then execute

    $ AUTH_PROXY_APP_DOMAIN=auth.my.domain AUTH_PROXY_COOKIE_DOMAIN=my.domain rackup config.ru


Now you can proxy requests through this app to be authenticated. One nice way of doing this is using nginx's
`auth_request` directive. Assuming you have different services under ops.company.tld domain
(service1.ops.company.tld service2.ops.company.tld etc) you would setup auth-proxy to run under
auth.ops.company.tld and keep the cookies under ops.company.tld so they will be available on all services:

    $ AUTH_PROXY_APP_DOMAIN=auth.ops.company.tld AUTH_PROXY_COOKIE_DOMAIN=ops.company.tld rackup -p 5000 config.ru

In front of the auth-proxy you will have an nginx (or more nginx loadbalancers) with the following config:

```
worker_processes 1;

events {
  worker_connections  1024;
}

http {
  upstream auth {
    server 127.0.0.1:6000 fail_timeout=0;
  }

  server {
    listen 80;
    server_name auth.ops.company.tld;

    location / {
      proxy_pass http://auth;
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }
  }
}
```

Now for each app that needs to be authenticated you will need a nginx in front of it with the following
config:

```
worker_processes 1;

events {
  worker_connections  1024;
}

http {
  upstream service1 {
    server 127.0.0.1:7000 fail_timeout=0;
  }


  server {
    listen 7000;
    server_name service1.ops.company.tld;

    auth_request /auth/try;

    # optional - if you need to pass to your app headers set by the auth-proxy
    auth_request_set $auth_proxy_user_name $upstream_http_x_auth_proxy_user_name;
    auth_request_set $auth_proxy_user_email $upstream_http_x_auth_proxy_user_email;
    auth_request_set $auth_proxy_user_id $upstream_http_x_auth_proxy_user_id;
    auth_request_set $auth_proxy_user_provider $upstream_http_x_auth_proxy_user_provider;
    auth_request_set $auth_proxy_user_token $upstream_http_x_auth_proxy_user_token;
    # optional end

    error_page 401 403 =200 @login;
    location @login {
      return 301 https://auth.ops.company.tld/login?return_to=https://$http_host$request_uri;
    }

    location = /auth/try {
      proxy_pass http://auth..ops.company.tld;
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";
    }

    location / {
      proxy_pass http://service1;
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      # optional - if you need to pass to your app headers set by the auth-proxy
      proxy_set_header X-Auth-Proxy-User-Name $auth_proxy_user_name;
      proxy_set_header X-Auth-Proxy-User-Email $auth_proxy_user_email;
      proxy_set_header X-Auth-Proxy-User-ID $auth_proxy_user_id;
      proxy_set_header X-Auth-Proxy-User-provider $auth_proxy_user_provider;
      proxy_set_header X-Auth-Proxy-User-token $auth_proxy_user_token;
      # optional end
    }
  }

}
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cristianbica/auth-proxy.

