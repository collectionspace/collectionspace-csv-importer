# frozen_string_literal: true

class MappersController < ApplicationController
  def index
    authorize(Mapper)
    @pagy, @mappers = pagy(
      policy_scope(Mapper).order(
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
end
