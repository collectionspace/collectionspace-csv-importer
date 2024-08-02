# frozen_string_literal: true

class Batch < ApplicationRecord
  include WorkflowManager
  ANY_EXPIRY_INTERVAL = 30 # (days) after which batch in any status will be deleted
  ARCHIVED_EXPIRY_INTERVAL = 7 # (days) after which archived batch will be deleted
  CONTENT_TYPES = [
    'application/vnd.ms-excel',
    'text/csv'
  ].freeze

  has_one_attached :spreadsheet
  has_one :step_preprocess, class_name: 'Step::Preprocess', dependent: :destroy
  has_one :step_process, class_name: 'Step::Process', dependent: :destroy
  has_one :step_transfer, class_name: 'Step::Transfer', dependent: :destroy
  has_one :step_archive, class_name: 'Step::Archive', dependent: :destroy
  belongs_to :user
  belongs_to :group
  belongs_to :connection
  belongs_to :mapper, counter_cache: true
  validates :spreadsheet, attached: true, content_type: CONTENT_TYPES
  validates :user, :group, :connection, :mapper, presence: true
  validates :name, presence: true, length: { minimum: 3 }
  validate :ensure_batch_config_is_json
  validate :connection_profile_is_matched

  scope :by_user, ->(email) { joins(:user).where('users.email LIKE (?)', email) }
  # tabs
  scope :archived, -> { where(step_state: 'archiving').where(status_state: 'finished') }
  scope :preprocesses, -> { where(step_state: 'preprocessing') }
  scope :processes, -> { where(step_state: 'processing') }
  scope :transfers, -> { where(step_state: 'transferring') }
  scope :working, lambda {
                    where.not("step_state = 'archiving' AND status_state = 'finished'")
                  }

  def any_expiry_interval
    ANY_EXPIRY_INTERVAL
  end

  def archived_expiry_interval
    ARCHIVED_EXPIRY_INTERVAL
  end

  def archived?
    step_archive&.done?
  end

  def can_cancel?
    %i[pending running].include? current_status
  end

  def can_reset?
    %i[cancelled failed].include? current_status
  end

  def expired?
    (archived? && (Time.now - step_archive.completed_at) > archived_expiry_interval.days) ||
      (Time.now - created_at > any_expiry_interval.days)
  end

  def fingerprint
    Digest::SHA2.hexdigest "#{id}-#{name}"
  end

  def record_mapper
    @record_mapper ||= fetch_mapper
  end

  def handler
    CollectionSpace::Mapper::DataHandler.new(
      record_mapper: record_mapper,
      client: connection.client,
      cache: connection.refcache,
      csid_cache: connection.csidcache,
      config: batch_config
    )
  end

  def job_is_active?
    return false unless job_id

    Sidekiq::WorkSet.new.find { |_pid, _tid, work| work['payload']['jid'] == job_id }
  end

  def processed?
    step_process&.done?
  end

  def preprocessed?
    step_preprocess&.done?
  end

  def transferred?
    step_transfer&.done?
  end

  def self.content_types
    CONTENT_TYPES
  end

  def self.csv_lint_validator_for(batch)
    # raise unless batch.spreadsheet.attached? # TODO

    batch.spreadsheet.open do |spreadsheet|
      config = { header: true, delimiter: ',' }
      validator = Csvlint::Validator.new(
        File.new(spreadsheet.path), config, nil
      )
      yield validator
    end
  end

  def self.csv_parse_validator_for(batch)
    # raise unless batch.spreadsheet.attached? # TODO

    batch.spreadsheet.open do |spreadsheet|
      yield batch.parse_spreadsheet(spreadsheet.path)
    end
  end

  def self.expired(&block)
    all.in_batches do |b|
      b.find_all(&:expired?).each(&block)
    end
  end

  def parse_spreadsheet(path)
    File.open(path, encoding: 'bom|utf-8') { |file| CSV.table(file) }
  rescue CSV::MalformedCSVError => e
    e.message
  else
    :success
  end

  private

  def ensure_batch_config_is_json
    json = JSON.parse(batch_config)

    unless json.is_a?(Hash) || json.is_a?(Array)
      errors.add(:batch_config, 'is invalid JSON')
    end
  rescue JSON::ParserError
    errors.add(:batch_config, 'is invalid JSON')
  end

  def connection_profile_is_matched
    return if connection && mapper && !(connection.profile != mapper.profile_version)

    errors.add(:mapper, I18n.t('batch.invalid_profile'))
  end

  def fetch_mapper
    Rails.cache.fetch(mapper.digest, namespace: 'mapper', expires_in: 1.day) do
      JSON.parse(mapper.config.download)
    end
  end
end
