# frozen_string_literal: true

class PreprocessJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false
  ERRORS = [:message].freeze
  PREPROCESS_FIELD_REPORT_COLS = %i[header known].freeze

  def perform(preprocess)
    manager = StepManagerService.new(
      step: preprocess, error_on_warning: false, save_to_file: false
    )
    return if manager.cut_short?

    manager.kickoff!

    begin
      handler = preprocess.batch.handler
    rescue CollectionSpace::Mapper::NoClientServiceError => e
      manager.add_error!
      manager.add_message("collectionspace-client does not have a service configured for #{e.message}")
      manager.exception!
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
    rescue CollectionSpace::Mapper::IdFieldNotInMapperError => e
      manager.add_error!
      manager.add_message('The import tool cannot determine the unique ID field for this record type. Contact import tool admin and ask them to fix the RecordMapper.')
      manager.exception!
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
    end

    begin
      empty_required = {}
      manager.process do |data|
        if manager.first?
          if missing_headers?(data)
            manager.add_message(I18n.t('csv.empty_header'))
            manager.add_error!
          end

          result = handler.check_fields(data)
          manager.add_message("#{I18n.t('csv.preprocess_known_prefix')}: #{result[:known_fields].count} of #{data.keys.count}")
          if result[:unknown_fields].any?
            manager.add_message("#{I18n.t('csv.preprocess_unknown_prefix')}: #{result[:unknown_fields].join('; ')}")
            manager.add_warning!
          end

          validated = handler.validate(data)

          unless validated.valid?
            missing_required = validated.errors.select do |err|
              err.start_with?('required field missing')
            end
            unless missing_required.empty?
              missing_required.each { |msg| manager.add_message(msg) }
              manager.add_error!
            end
          end
        end

        validated = handler.validate(data)

        unless validated.valid?
          errs = validated.errors.reject do |err|
            err.start_with?('required field missing')
          end
          errs.each { |e| empty_required[e] = nil } unless errs.empty?
        end
      end

      unless empty_required.empty?
        empty_required.each_key do |msg|
          manager.add_message("In one or more rows, #{msg}")
        end
        manager.add_error!
      end

      manager.complete!
    rescue StandardError => e
      manager.exception!
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
    end
  end

  private

  def missing_headers?(data)
    !data.keys.select(&:blank?).empty?
  end
end
