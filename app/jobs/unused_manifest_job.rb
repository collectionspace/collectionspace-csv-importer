# frozen_string_literal: true

class UnusedManifestJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false

  def perform
    Manifest.unused(&:destroy)
  end
end
