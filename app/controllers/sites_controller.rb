# frozen_string_literal: true

class SitesController < ApplicationController
  before_action :set_gems, :set_system, only: %i[sysinfo]
  skip_before_action :verify_authenticity_token, only: %i[update_status]

  def home
    skip_authorization
    skip_policy_scope
  end

  def sysinfo
    authorize SystemInformation
  end

  # rubocop:disable Lint/SuppressedException
  def update_status
    model = params['model'].camelize.constantize
    record = model.find(params['id'])
    begin
      authorize record
      record.update(enabled: !record.enabled)
    rescue Pundit::NotAuthorizedError
    end
    render partial: 'shared/update_status', locals: { type: params['model'], this: record, opts: {} }
  end
  # rubocop:enable Lint/SuppressedException

  private

  def set_gems
    @gems = SystemInformation.gems
  end

  def set_system
    @system = SystemInformation.system_summary(
      Rails.cache.fetch('sysinfo', namespace: 'sysinfo', expires_in: 1.day) do
        SystemInformation.system
      end
    )
  end
end
