# frozen_string_literal: true

class ManifestPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def create?
    user.admin?
  end

  def update_status?
    user.manage?(record)
  end

  def destroy?
    user.admin?
  end

  def permitted_attributes_for_create
    %i[name url]
  end

  class Scope < Scope
    def resolve
      scope.all if user.admin?
    end
  end
end
