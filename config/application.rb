# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CollectionSpaceCsvImporter
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
    # https://github.com/mperham/sidekiq/wiki/Active-Job#queues
    config.action_mailer.deliver_later_queue_name = nil
    config.active_storage.queues.analysis   = nil
    config.active_storage.queues.purge      = nil
    config.active_storage.queues.mirror     = nil

    config.application_support_email = ENV.fetch(
      'APPLICATION_SUPPORT_EMAIL', 'collectionspace@lyrasis.org'
    )

    config.csidcache_url = ENV.fetch('REDIS_CSIDCACHE_URL') do
      ENV.fetch('REDIS_URL', 'redis://localhost:6379/5')
    end

    config.csv_max_rows = ENV.fetch('CSV_MAX_ROWS', 10_000).to_i

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
