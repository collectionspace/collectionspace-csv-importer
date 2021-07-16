# frozen_string_literal: true

class ManifestReflex < ApplicationReflex
  def cleanup
    morph :nothing
    sleep 0.5
    Manifest.find(element.data_id.to_i).clean_up
    # TODO: ManifestCleanupJob.perform_later(Manifest.find(element.data_id.to_i))
  end

  def import
    morph :nothing
    sleep 0.5
    Manifest.find(element.data_id.to_i).refresh
    # TODO: ManifestImportJob.perform_later(Manifest.find(element.data_id.to_i))
  end

  def selected
    @manifest = Manifest.find(element.value.to_i)
    session[:manifest] = @manifest.name
  end
end
