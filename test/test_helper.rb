# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require_relative 'test_support'
require_relative 'caching_helper'
require_relative 'job_helper'

require 'rails/test_help'
require 'minitest/autorun'
require 'aasm/minitest'
require 'webmock/minitest'

WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    'github.com',
    /github-production-release-asset-*/,
    'github-releases.githubusercontent.com',
    'googlechromelabs.github.io',
    'storage.googleapis.com'
  ]
)

# clear test cache b4 run
Rails.cache.clear

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)
  parallelize(workers: 1)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  include Devise::Test::IntegrationHelpers
  include Integration::TestMethods
  include Policy::TestMethods
end
