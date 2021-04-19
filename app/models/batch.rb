# frozen_string_literal: true

class Batch < ApplicationRecord
  include WorkflowManager
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
  scope :working, -> { where.not("step_state = 'archiving' AND status_state = 'finished'") }

  def archived?
    step_archive&.done?
  end

  def can_cancel?
    %i[pending running].include? current_status
  end

  def can_reset?
    %i[cancelled failed].include? current_status
  end

  def handler
    @rm ||= fetch_mapper
    CollectionSpace::Mapper::DataHandler.new(
      # Leaving this here because I suspect we will want to revert to the commented version once bug
      #  with check_terms = false when using it can be squashed.
      # record_mapper: @rm, client: connection.client, cache: connection.refcache, config: batch_config
      record_mapper: @rm, client: connection.client, config: batch_config
    )
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

  def self.csv_validator_for(batch)
    # raise unless batch.spreadsheet.attached? # TODO

    batch.spreadsheet.open do |spreadsheet|
      config = { 'header': true, 'delimiter': ',' }
      validator = Csvlint::Validator.new(
        File.new(spreadsheet.path), config, nil
      )
      yield validator
    end
  end

  private

  def ensure_batch_config_is_json
    self.batch_config = JSON.parse(batch_config.to_s)
  rescue JSON::ParserError
    errors.add(:batch_config, 'is invalid JSON')
  end

  def connection_profile_is_matched
    if connection && mapper
      return unless connection.profile != mapper.profile_version
    end

    errors.add(:profile, I18n.t('batch.invalid_profile'))
  end

  def fetch_mapper
    Rails.cache.fetch(mapper.title, namespace: 'mapper', expires_in: 1.day) do
      JSON.parse(mapper.config.download)
    end
  end
end
