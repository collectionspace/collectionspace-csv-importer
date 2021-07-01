# frozen_string_literal: true

class MappersController < ApplicationController
  before_action :set_manifest, only: %i[index]

  def index
    authorize(Mapper)
    @pagy, @mappers = pagy(
      policy_scope(Mapper).by_manifest(@manifest.name).order(
        'mappers.profile asc, mappers.version asc, mappers.type asc'
      ),
      items: 25
    )
  end

  # OTHER

  def autocomplete
    authorize(Mapper)
    q = params[:query]
    results = Mapper.profile_versions.find_all do |mp|
      mp.starts_with?(q)
    end.map do |mp|
      mp.gsub(/^#{q}/, highlight(q))
    end

    render json: results.map { |mp| { value: mp } }
  end

  private

  def set_manifest
    name = session.fetch(:manifest, Manifest.last.name)
    @manifest = Manifest.where(name: name).first
    session[:manifest] = @manifest.name
  end
end
