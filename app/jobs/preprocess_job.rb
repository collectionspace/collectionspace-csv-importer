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
      begin
        handler = preprocess.batch.handler
      rescue CollectionSpace::Mapper::IdFieldNotInMapperError
        manager.add_error!
        manager.add_message('The import tool cannot determine the unique ID field for this record type.
Contact import tool admin and ask them to fix the RecordMapper.')
      else
        empty_required = {}
        manager.process do |data|
          if manager.first?
            result = handler.check_fields(data)
            manager.add_message("#{I18n.t('csv.preprocess_known_prefix')}: #{result[:known_fields].count} of #{data.keys.count}")
            if result[:unknown_fields].any?
              manager.add_message("#{I18n.t('csv.preprocess_unknown_prefix')}: #{result[:unknown_fields].join('; ')}")
              manager.add_warning!
            end

            validated = handler.validate(data)
            unless validated.valid?
              missing_required = validated.errors.select { |err| err.start_with?('required field missing') }
              unless missing_required.empty?
                missing_required.each { |msg| manager.add_message(msg) }
                manager.add_error!
              end
            end
          end

          validated = handler.validate(data)
          unless validated.valid?
            errs = validated.errors.reject { |err| err.start_with?('required field missing') }
            errs.each { |e| empty_required[e] = nil } unless errs.empty?
          end
        end

        unless empty_required.empty?
          empty_required.each_key { |msg| manager.add_message("In one or more rows, #{msg}") }
          manager.add_error!
        end

        manager.complete!
      end
    rescue StandardError => e
      manager.exception!
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
    end
  end
end
