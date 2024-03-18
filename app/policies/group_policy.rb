# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def create?
    user.manage?(record)
  end

  def update?
    user.manage?(record)
  end

  def update_status?
    return false if record.default?

    user.manage?(record)
  end

  def edit?
    update?
  end

  def destroy?
    return false if record.default?

    user.manage?(record)
  end

  def permitted_attributes
    if user.manage?(record) && record.default?
      %i[name description email]
    elsif user.manage?(record)
      %i[name description domain email enabled profile]
    else
      []
    end
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.group_id)
      end
    end
  end
end
