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

  def client
    CollectionSpace::Client.new(
      CollectionSpace::Configuration.new(
        base_uri: url,
        username: username,
        password: password
      )
    )
  end

  def disabled?
    !enabled?
  end

  def enabled?
    enabled
  end

  def resolve_primary
    Connection.resolve_primary(user, self)
  end

  def primary?
    primary
  end

  def refcache
    @cache_config ||= {
      redis: Rails.configuration.refcache_url,
      domain: client.config.base_uri,
      error_if_not_found: false,
      lifetime: 5 * 60,
      search_delay: 5 * 60,
      search_enabled: true,
      search_identifiers: false
    }
    CollectionSpace::RefCache.new(config: @cache_config, client: client)
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
    return if Rails.env.test?

    if username.blank? || password.blank?
      errors.add(:verify_error, 'username and password are required to verify user')
      return
    end

    response = client.get('accounts/0/accountperms')
    unless response.result.success? &&
           response.parsed.respond_to?(:dig) &&
           response.parsed.dig('account_permission', 'account', 'userId') == username
      errors.add(:verify_error, 'user account lookup failed')
    end
  end

  def inherit_profile
    self.profile = user.group.profile if profile.blank?
  end
end
