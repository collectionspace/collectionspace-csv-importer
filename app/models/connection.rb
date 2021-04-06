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
  after_save :set_domain
  validates :name, :profile, :url, :username, presence: true
  validates :password, presence: true, length: { minimum: 6, maximum: 18 }
  validate :profile_must_be_prefix

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

  def domain_for_env
    Rails.env.test? ? 'test.collectionspace.org' : client.domain
  end

  def inherit_profile
    self.profile = user.group.profile if profile.blank?
  end

  def set_domain
    update_column :domain, domain_for_env
  rescue CollectionSpace::RequestError, SocketError => e
    update_columns(domain: nil, enabled: false, primary: false)
    logger.error(e.message)
  end
end
