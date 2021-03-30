# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_SIDEKIQ_URL') do
      ENV.fetch('REDIS_URL', 'redis://localhost:6379/2')
    end
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_SIDEKIQ_URL') do
      ENV.fetch('REDIS_URL', 'redis://localhost:6379/2')
    end
  }
end

require 'sidekiq/web'
# CSRF: https://github.com/mperham/sidekiq/wiki/Monitoring#web-ui
Sidekiq::Web.set :session_secret, Rails.application.credentials[:secret_key_base]
