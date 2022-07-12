# frozen_string_literal: true

class SystemInformationPolicy < ApplicationPolicy
  def sysinfo?
    user.admin?
  end
end
