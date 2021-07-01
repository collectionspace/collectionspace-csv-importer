# frozen_string_literal: true

class ManifestReflex < ApplicationReflex
  def selected
    @manifest = Manifest.find(element.value.to_i)
    session[:manifest] = @manifest.name
  end
end
