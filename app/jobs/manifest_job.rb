# frozen_string_literal: true

class ManifestJob < ApplicationJob
  include CableReady::Broadcaster
  queue_as :default
  sidekiq_options retry: false

  def perform(manifest, task)
    manifest.send(task) do |_|
      stream_progress manifest, task
    end

    stream_finalize manifest, task
  end

  def stream_finalize(manifest, task)
    cable_ready['manifest'].morph(
      selector: "#manifest_#{manifest.id} ##{task} i",
      html: '<i class="fa fa-refresh"></i>'
    ).broadcast
  end

  def stream_progress(manifest, task)
    cable_ready['manifest'].text_content(
      selector: "#manifest_#{manifest.id} .mappers_count",
      text: manifest.mappers_count
    ).broadcast

    cable_ready['manifest'].morph(
      selector: "#manifest_#{manifest.id} ##{task} i",
      html: '<i class="fa fa-refresh fa-spin"></i>'
    ).broadcast
  end
end
