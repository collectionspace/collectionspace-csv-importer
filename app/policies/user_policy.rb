# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    user.enabled?
  end

  def update?
    return false if record.superuser? && !user.superuser?

    user.manage?(record)
  end

  def update_group?
    user.manage?(record)
  end

  def update_status?
    return false if record.superuser?
    return false if user.is?(record)

    user.manage?(record)
  end

  def edit?
    update?
  end

  def destroy?
    return false if record.superuser?

    user.manage?(record) && !user.is?(record)
  end

  def impersonate?
    return false if record.superuser?

    user.manage?(record) && !user.is?(record)
  end

  def permitted_attributes
    if user.admin? && !user.is?(record)
      %i[password password_confirmation active enabled group_id role_id]
    elsif user.manage?(record) && !user.is?(record)
      %i[password password_confirmation active enabled role_id]
    else
      # allows a user to update own group (affiliation)
      %i[password password_confirmation group_id]
    end
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        # all users in this users group (excluding affiliations)
        user.group.users.where(group: user.group)
      end
    end
  end
end
