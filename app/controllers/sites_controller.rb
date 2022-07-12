# frozen_string_literal: true

class SitesController < ApplicationController
  before_action :set_gems, :set_system, only: %i[sysinfo]

  def home
    skip_authorization
    skip_policy_scope
  end

  def sysinfo
    authorize SystemInformation
  end

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
