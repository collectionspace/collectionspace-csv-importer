# frozen_string_literal: true

class BatchExpiredJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false

  def perform
    Batch.expired(&:destroy)
  end
end
