# frozen_string_literal: true

class ReaperExpiredJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false

  def perform
    Batch.expired(&:destroy)
  end
end
