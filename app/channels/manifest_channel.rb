# frozen_string_literal: true

class ManifestChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'manifest'
  end
end
