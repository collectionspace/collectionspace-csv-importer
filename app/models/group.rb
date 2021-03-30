# frozen_string_literal: true

class Group < ApplicationRecord
  include PrefixChecker
  # has_and_belongs_to_many :users, dependent: :destroy
  has_many :affiliations
  has_many :users, through: :affiliations
  has_many :batches, dependent: :destroy
  has_many :connections, through: :users
  after_save :update_connection_profiles, if: -> { profile? }
  validate :profile_must_be_prefix
  validates :name, presence: true, uniqueness: true
  validates :supergroup, uniqueness: true, if: -> { supergroup }
  validates_uniqueness_of :domain, allow_blank: true
  scope :default, -> { where(supergroup: true).first }
  scope :select_options, ->(user) { (user.admin? ? all : user.groups) }
  scope :select_options_with_default, ->(user) { select_options(user) }
  scope :select_options_without_default, ->(user) { select_options(user).where.not(id: default.id) }

  after_create do
    User.admins.each { |user| user.groups << self }
  end

  before_destroy do
    Affiliation.where(group: self).destroy_all
    User.where(group: self).destroy_all
  end

  def default?
    self == Group.default
  end

  def disabled?
    !enabled?
  end

  def enabled?
    enabled
  end

  def profile?
    !profile.blank?
  end

  def self.default_created?
    Group.default
  end

  def self.matching_domain?(domain)
    return [] if domain.blank?

    Group.all.select do |g|
      next if g.domain.blank?

      domain.end_with?(g.domain)
    end.sort_by { |g| domain.length - g.domain.length }
  end

  private

  def update_connection_profiles
    connections.update_all(profile: profile)
  end
end
