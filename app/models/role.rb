# frozen_string_literal: true

class Role < ApplicationRecord
  has_many :users

  TYPE = {
    admin: 'Admin',
    manager: 'Manager',
    member: 'Member'
  }.freeze

  scope :admin, -> { where(name: TYPE[:admin]).first }
  scope :default, -> { where(name: TYPE[:member]).first }
  scope :manager, -> { where(name: TYPE[:manager]).first }
  scope :member, -> { where(name: TYPE[:member]).first }
  scope :select_options, ->(user) { user.admin? ? all : where.not(name: TYPE[:admin]) }

  class Type
    attr_reader :user
    def initialize(user)
      @user = user
    end

    # implement in subclass
    def collaborator?(_record)
      false
    end

    def manage?(record)
      return false if record.nil?

      collaborator?(record)
    end
  end

  class Admin < Type
    def collaborator?(_record)
      true
    end
  end

  class Manager < Type
    def collaborator?(record)
      return true if user.is?(record)
      return true if user.group?(record)
      return false if record.respond_to?(:role) && record.admin?

      if record.respond_to?(:group)
        user.group.id == record.group.id
      elsif record.respond_to?(:user)
        user.group.id == record.user.group.id
      end
    end
  end

  class Member < Type
    def collaborator?(record)
      return true if user.is?(record) || user.owner_of?(record)
    end
  end
end
