# frozen_string_literal: true

class ConnectionPolicy < ApplicationPolicy
  def create?
    true
  end

  def update?
    user.manage?(record)
  end

  def update_status?
    user.manage?(record)
  end

  def edit?
    update?
  end

  def destroy?
    user.manage?(record)
  end

  def permitted_attributes_for_create
    %i[name url username password enabled primary profile]
  end

  def permitted_attributes_for_update
    if user.manage?(record)
      %i[name url username password enabled primary profile]
    else
      []
    end
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
