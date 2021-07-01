# frozen_string_literal: true

class ManifestPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def create?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def permitted_attributes_for_create
    %i[url]
  end

  class Scope < Scope
    def resolve
      scope.all if user.admin?
    end
  end
end
