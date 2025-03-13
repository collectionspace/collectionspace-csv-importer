# frozen_string_literal: true

class ProcessJob < ApplicationJob
  include MediaRectype

  queue_as :default
  sidekiq_options retry: false
  ERRORS = [:message].freeze

  def perform(processing)
    @step = processing
    @batchid = @step.batch.id
    @manager = StepManagerService.new(
      step: @step, error_on_warning: false, save_to_file: false
    )
    return if @manager.cut_short?

    @manager.kickoff!

    begin
      @cachesvc = RecordCacheService.new(batch_id: @batchid)
      @repsvc = ReportService.new(name: "#{@manager.filename_base}_processed",
                                  columns: %i[row row_occ header message],
                                  save_to_file: true)
      @manager.add_file(@repsvc.file, 'text/csv', :tmp)

      @uniqsvc = RecordUniquenessService.new(log_report: @repsvc)

      @termsvc = MissingTermService.new(batch: @step.batch)
      @manager.add_file(@termsvc.missing_term_occurrence_file, 'text/csv', :tmp)

      process_rows

      report_missing_terms_for_batch
      report_nonunique_ids_in_batch

      Rails.logger.info("Batch #{@batchid}: Preparing final processing "\
                        'report')
      final_report = ProcessingReportFinalizerService.call(
        base_name: @manager.filename_base,
        orig_file: @step.batch.spreadsheet,
        merge_file_path: @repsvc.file.to_s
      )
      @manager.add_file(final_report, 'text/csv')
      @manager.complete!
    rescue StandardError => e
      @manager.exception!
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
    end
  end

  private

  def process_rows
    @manager.process { |data| process_row(data, @step.batch.handler) }
  end

  def process_row(data, handler)
    row_num = @step.step_num_row
    data = data.compact.transform_keys!(&:downcase)

    results = map_row(data, handler, row_num)

    handle_results(results, row_num, data) if results

    @step.save
  end

  def map_row(data, handler, row_num)
    [handler.process(data)].flatten
  rescue StandardError => e
    Rails.logger.error("Batch #{@batchid} - Row #{row_num}")
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace)

    @manager.add_warning!
    @repsvc.append({ row: row_num,
                     header: 'ERR: mapper',
                     message: 'Mapper did not return result for unexpected '\
                              'reason. Please send a copy of this report to '\
                              'collectionspace@lyrasis.org. We will use the '\
                              'following info to diagnose and fix the '\
                              'problem, but you may ignore it: '\
                              "#{e.message} -- #{e.backtrace.first}" })
    @manager.add_message('Mapping failed for one or more records')
    nil
  end

  def handle_results(results, row_num, data)
    results.each_with_index do |result, idx|
      handle_result(result, idx, row_num, data)
    end
  end

  def handle_result(result, idx, row_num, data)
    row_occ = "#{row_num}.#{idx + 1}"
    record_row_info_and_status(row_num, row_occ, result.record_status)

    id = result.identifier
    handle_id(id, row_num, row_occ)
    handle_missing_terms(result, row_num, row_occ)
    handle_warnings(result, row_occ)
    handle_errors(result, row_occ)
    return unless result.errors.empty?

    cache_result_for_transfer(data, result, row_occ)
  end

  def record_row_info_and_status(row_num, row_occ, status)
    [
      ['INFO: rownum', row_num],
      ['INFO: rowoccurrence', row_occ],
      ['INFO: record status', status]
    ].each do |header, value|
      @repsvc.append({ row: row_num,
                       row_occ: row_occ,
                       header: header,
                       message: value })
    end
  end

  def handle_id(id, row_num, row_occ)
    return handle_missing_id(row_num, row_occ) if id.nil? || id.empty?

    @uniqsvc.add(row_num: row_num, row_occ: row_occ, rec_id: id)

    service_type = @step.batch.record_mapper['config']['service_type']
    return unless service_type == 'relation'

    @repsvc.append({ row: row_num,
                     row_occ: row_occ,
                     header: 'INFO: relationship id',
                     message: id })
  end

  def handle_missing_id(row_num, row_occ)
    @repsvc.append({ row: row_num,
                     row_occ: row_occ,
                     header: 'ERR: record id',
                     message: 'Identifier for record not found or created' })
    @manager.add_message('No identifier value for one or more records')
    @manager.add_error!
  end

  def handle_missing_terms(result, row_num, row_occ)
    missing_terms = @termsvc.get_missing(result.terms)
    return if missing_terms.empty?

    Rails.logger.info("Batch #{@batchid}, row occ #{row_occ}: handling "\
                      'missing terms')
    missing_terms.each { |term| @termsvc.add(term, row_num, row_occ) }
    @manager.add_warning!
  end

  def handle_warnings(result, row_occ)
    return if result.warnings.empty?

    Rails.logger.info("Batch #{@batchid}: Handling warnings")
    result.warnings.each do |warning|
      @manager.handle_processing_warning(@repsvc, row_occ, warning)
    end
  end

  def handle_errors(result, row_occ)
    return if result.errors.empty?

    Rails.logger.info("Batch #{@batchid}: Handling errors")
    result.errors.each do |err|
      @manager.handle_processing_error(@repsvc, row_occ, err)
    end
  end

  def cache_result_for_transfer(data, result, row_occ)
    if is_media?(@step.batch.mapper.type) && !data['mediafileuri'].blank?
      @cachesvc.cache_processed(row_occ, result, data['mediafileuri'])
    else
      @cachesvc.cache_processed(row_occ, result)
    end
  end

  def report_missing_terms_for_batch
    return if @termsvc.total_terms == 0

    Rails.logger.info("Batch #{@batchid}: Reporting missing terms")
    @termsvc.report_uniq_missing_terms
    @manager.add_file(@termsvc.uniq_missing_terms_file, 'text/csv')
    @manager.add_message("Batch contains #{@termsvc.total_terms} unique terms "\
                         'that do not exist in CollectionSpace')
    @manager.add_message("Batch contains #{@termsvc.total_term_occurrences} "\
                         'uses of terms that do not exist in CollectionSpace')
  end

  def report_nonunique_ids_in_batch
    Rails.logger.info("Batch #{@batchid}: Finding/reporting any "\
                      'non-unique record ids in batch')
    return unless @uniqsvc.any_non_unique?

    @uniqsvc.report_non_unique
    @manager.add_warning!
    @manager.add_message("#{@uniqsvc.non_unique_count} rows have non-unique "\
                         'identifiers')
  end
end
