# frozen_string_literal: true

module CachingHelper
  # TODO: deprecated
  def with_caching
    Rails.application.config.cache_store = [
      :memory_store, { size: 64.megabytes }
    ]
    Rails.cache = ActiveSupport::Cache::MemoryStore.new(
      expires_in: 1.minute
    )
    cache_store_type_origin = Rails.application.config.cache_store
    cache_store_origin = Rails.cache
    yield
  ensure
    Rails.cache.clear
    Rails.cache = cache_store_origin
    Rails.application.config.cache_store = cache_store_type_origin
  end
end
