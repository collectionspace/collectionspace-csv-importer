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

  def create
    @manifest = Manifest.new
    if @manifest.update(permitted_attributes(@manifest))
      respond_to do |format|
        format.html do
          redirect_to manifests_path
        end
      end
    else
      redirect_to manifests_path, alert: error_messages(@manifest.errors)
    end
  end

  def destroy
    # TODO: make this more efficient
    @manifest.mappers.each { |m| m.destroy if m.batches_count.zero? }
    if @manifest.mappers_count.zero?
      @manifest.destroy
      respond_to do |format|
        format.html do
          redirect_to manifests_url, notice: t('action.deleted', record: 'Manifest')
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to manifests_url, alert: t('action.record_in_use', record: 'Manifest')
        end
      end
    end
  end

  private

  def set_manifest
    @manifest = authorize Manifest.find(params[:id])
  end
end
