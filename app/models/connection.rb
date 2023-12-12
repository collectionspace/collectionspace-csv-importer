# frozen_string_literal: true

class Connection < ApplicationRecord
  include PrefixChecker
  belongs_to :user, counter_cache: true
  belongs_to :group
  has_many :batches, dependent: :nullify # TODO: alrighty?
  encrypts :password
  before_save :resolve_primary, if: -> { primary? }
  before_save :unset_primary, if: -> { disabled? && primary? }
  before_validation :inherit_profile
  validates :name, :profile, :url, :username, presence: true
  validates :password, presence: true, length: { minimum: 6, maximum: 18 }
  validate :profile_must_be_prefix
  validate :verify_user

  def authorized?
    return true if Rails.env.test? # TODO: stub response in tests

    response = client.get('accounts/0/accountperms')
    response.result.success? &&
      response.parsed.respond_to?(:dig) &&
      response.parsed.dig('account_permission', 'account', 'userId') == username
  end

  def client
    CollectionSpace::Client.new(
      CollectionSpace::Configuration.new(
        base_uri: url,
        username: username,
        password: password
      )
    )
  end

  def csidcache
    @csidcache_config ||= {
      redis: Rails.configuration.csidcache_url,
      domain: client.config.base_uri,
      lifetime: 5 * 60,
    }
    CollectionSpace::RefCache.new(config: @csidcache_config)
  end

  def disabled?
    !enabled?
  end

  def enabled?
    enabled
  end

  def primary?
    primary
  end

  def refcache
    @cache_config ||= {
      redis: Rails.configuration.refcache_url,
      domain: client.config.base_uri,
      lifetime: 5 * 60,
    }
    CollectionSpace::RefCache.new(config: @cache_config)
  end

  def resolve_primary
    Connection.resolve_primary(user, self)
  end

  def unset_primary
    self.primary = false
  end

  def self.resolve_primary(user, connection)
    where(user_id: user.id)
      .where.not(id: connection.id)
      .update_all(primary: false)
  end

  private

  def verify_user
    return if Rails.env.test? # TODO: stub response in tests

    if username.blank? || password.blank?
      errors.add(:verify_error, 'username and password are required to verify user')
      return
    end

    unless authorized?
      errors.add(:verify_error, 'connection or user account lookup failed')
    end
  end

  def inherit_profile
    self.profile = user.group.profile if profile.blank?
  end
end
