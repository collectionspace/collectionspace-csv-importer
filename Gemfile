# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.6'

# RAILS GEMS
gem 'activerecord-nulldb-adapter' # pre-compile assets w/o a real db connection
gem 'bootsnap', '>= 1.4.2', require: false
gem 'jbuilder', '~> 2.7'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.1'
gem 'rails', '~> 6.0.3', '>= 6.0.3.2'
gem 'sass-rails', '>= 6'
gem 'turbolinks', '~> 5'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'webpacker', '~> 4.0'

# APP GEMS
gem 'aasm'
gem 'active_storage_validations'
gem 'after_commit_everywhere', '~> 0.1', '>= 0.1.5'
gem 'aws-sdk-s3', require: false
gem 'bulma-rails', '~> 0.9.0'

gem 'collectionspace-client', tag: 'v0.15.1', git: 'https://github.com/collectionspace/collectionspace-client.git'
gem 'collectionspace-refcache', tag: 'v1.0.0', git: 'https://github.com/collectionspace/collectionspace-refcache.git'
gem 'collectionspace-mapper', tag: 'v4.1.3', git: 'https://github.com/collectionspace/collectionspace-mapper.git'

gem 'csvlint',
  git: 'https://github.com/lyrasis/csvlint.rb.git',
  tag: 'v1.4.0'
gem 'devise'
gem 'font-awesome-rails'
# gem 'hiredis'
gem 'http'
gem 'local_time'
gem 'lockbox'
gem 'ohai'
gem 'pagy', '~> 3.5'
gem 'pretender'
gem 'psych', '< 4'
gem 'pundit'
gem 'redis', '>= 4.0' # , require: ['redis', 'redis/connection/hiredis']
gem 'redis-session-store'
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'stimulus_reflex', '~> 3.4'

# DEV / TEST GEMS
group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'debug'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'
end

group :development do
  gem 'listen', '~> 3.2'
  gem 'rubocop'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'webmock'
end
