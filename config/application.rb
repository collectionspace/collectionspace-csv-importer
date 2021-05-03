# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CspaceBatchImport
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.active_job.queue_adapter = :sidekiq
    # We don't need these for our csv / excel uploads
    config.active_storage.analyzers = []
    config.active_storage.previewers = []

    config.mappers_url = ENV.fetch(
      'MAPPERS_URL', 'https://raw.githubusercontent.com/collectionspace/cspace-config-untangler/main/data/mapper_manifests/dev_mappers.json'
    )

    config.application_support_email = ENV.fetch(
      'APPLICATION_SUPPORT_EMAIL', 'collectionspace@lyrasis.org'
    )

    config.refcache_url = ENV.fetch('REDIS_REFCACHE_URL') do
      ENV.fetch('REDIS_URL', 'redis://localhost:6379/3')
    end

    config.superuser_email = ENV.fetch(
      'SUPERUSER_EMAIL', 'superuser@collectionspace.org'
    )
    config.superuser_password = ENV.fetch(
      'SUPERUSER_PASSWORD', 'password'
    )
  end
end
