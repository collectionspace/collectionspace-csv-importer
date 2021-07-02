# frozen_string_literal: true

class ManifestsController < ApplicationController
  before_action :set_manifest, only: %i[destroy]

  def index
    authorize(Manifest)
    @pagy, @manifests = pagy(
      policy_scope(Manifest).order(:name),
      items: 25
    )
  end

  def destroy
    @manifest.destroy
    respond_to do |format|
      format.html do
        redirect_to manifests_url,
                    notice: t('action.deleted', record: 'Manifest')
      end
    end
  end

  private

  def set_manifest
    @manifest = authorize Manifest.find(params[:id])
  end
end
