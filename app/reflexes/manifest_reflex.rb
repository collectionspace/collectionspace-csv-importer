# frozen_string_literal: true

class ManifestReflex < ApplicationReflex
  def cleanup
    morph :nothing
    sleep 0.5
    ManifestJob.perform_later(
      Manifest.find(element.data_id.to_i), :clean_up
    )
  end

  def import
    morph :nothing
    sleep 0.5
    ManifestJob.perform_later(
      Manifest.find(element.data_id.to_i), :import
    )
  end

  def selected
    @manifest = Manifest.find(element.value.to_i)
    session[:manifest] = @manifest.name
  end
end
