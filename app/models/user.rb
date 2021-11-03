# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :validatable

  has_many :batches, dependent: :destroy
  has_many :connections, dependent: :destroy
  belongs_to :group # this is the current group
  has_many :affiliations
  has_many :groups, through: :affiliations do
    def <<(new_item)
      super(Array(new_item) - proxy_association.owner.groups)
    end
  end
  belongs_to :role
  after_initialize :setup, if: :new_record?
  before_save :reset_admin_group
  validate :group_is_affiliated, unless: :new_record?
  validates :superuser, uniqueness: true, if: -> { superuser }
  validates_presence_of :password, if: :password_confirmation
  validates_presence_of :password_confirmation, if: :password
  scope :superuser, -> { where(superuser: true).first }
  scope :admins, -> { where(role_id: Role.default_scoped.admin.id) }

  def active_for_authentication?
    super && active?
  end

  def active?
    active
  end

  def admin?
    role == Role.default_scoped.admin
  end

  # TODO: test
  def affiliated_with?(group)
    groups.exists?(group.id)
  end

  def default_connection
    connection = connections.where(group: group, primary: true).first
    connection ||= connections.where(group: group, enabled: true).first
    connection
  end

  def disabled?
    !enabled?
  end

  def enabled?
    enabled && group.enabled?
  end

  def group?(group)
    self.group == group
  end

  def is?(user)
    self == user
  end

  def manage?(record)
    "Role::#{role.name}".constantize.new(self).manage?(record)
  end

  def manager?
    role == Role.manager
  end

  def member?
    role == Role.member
  end

  def owner_of?(record)
    self == record.user if record.respond_to?(:user)
  end

  def role?(name)
    role.name == name
  end

  def setup
    self.group ||= target_group
    groups << self.group # add this group to our list of affiliate groups
    self.role ||= target_role
    self.enabled ||= self.role == Role.manager
  end

  def superuser?
    is?(User.superuser)
  end

  def self.superuser_created?
    User.superuser
  end

  private

  def group_is_affiliated
    unless affiliations.where(group: group).one?
      errors.add(:group, I18n.t('user.unaffiliated_group'))
    end
  end

  def reset_admin_group
    if self.role == Role.admin && self.group != Group.default
      self.group = Group.default
      groups.destroy_all
      groups << Group.all
    end
  end

  def target_group
    g = Group.matching_domain?(email.split('@').last)
    g.any? ? g.first : Group.default
  end

  def target_role
    if self.group != Group.default && self.group.users.where.not(role: Role.admin).count.zero?
      Role.manager
    else
      Role.default
    end
  end
end
