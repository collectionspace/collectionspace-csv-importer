# frozen_string_literal: true

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_store = :redis_cache_store, {
    namespace: 'ccit',
    url: ENV.fetch('REDIS_CACHE_URL') do
      ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
    end,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
  config.session_store :redis_session_store,
                       key: '_importer_session_test',
                       serializer: :json,
                       redis: {
                         expire_after: 1.day,
                         ttl: 1.day,
                         key_prefix: 'ccit:session:',
                         url: ENV.fetch('REDIS_SESSION_URL') do
                                ENV.fetch('REDIS_URL', 'redis://localhost:6379/4')
                              end,
                         ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
                       }

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    # config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.cache_classes = false
  config.action_view.cache_template_loading = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true
end
