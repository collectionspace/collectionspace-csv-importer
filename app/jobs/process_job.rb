# frozen_string_literal: true
require 'pp'

class ProcessJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false
  ERRORS = [:message].freeze

  def perform(process)
    manager = StepManagerService.new(
      step: process, error_on_warning: false, save_to_file: false
    )
    return if manager.cut_short?

    manager.kickoff!

    begin
      handler = process.batch.handler
      rcs = RecordCacheService.new(batch: process.batch)

      rep = ReportService.new(name: "#{manager.filename_base}_processed",
                              columns: %i[row row_occ header message],
                              save_to_file: true)
      manager.add_file(rep.file, 'text/csv', :tmp)

      rus = RecordUniquenessService.new(batch: process.batch, log_report: rep)

      mts = MissingTermService.new(batch: process.batch, save_to_file: true)
      manager.add_file(mts.missing_term_occurrence_file, 'text/csv', :tmp)
      
      manager.process do |data|
        row_num = process.step_num_row
        data = data.compact
        begin
          results = [handler.process(data)].flatten
        rescue StandardError => e
          manager.add_warning!
          rep.append({row: row_num,
                      header: 'ERR: mapper',
                      message: "Mapper did not return result: #{e.message} -- #{e.backtrace.first}",
                     })
          manager.add_message("Mapping failed for one or more records")
          next	
        end

        results.each_with_index do |result, i|
          row_occ = "#{row_num}.#{i + 1}"
          # write row number for later merge with transfer results
          rep.append({row: row_num,
                      row_occ: row_occ,
                      header: 'INFO: rownum',
                      message: row_num,
                     })
          # write row occurrence number for later merge with transfer results
          rep.append({row: row_num,
                      row_occ: row_occ,
                      header: 'INFO: rowoccurrence',
                      message: row_occ,
                     })
          # write record status for collation into final report
          rep.append({row: row_num,
                      row_occ: row_occ,
                      header: 'INFO: record status',
                      message: result.record_status,
                     })

          missing_terms = result.terms.empty? ? [] : mts.get_missing(result.terms)
          
          unless missing_terms.empty?
            puts 'Handling missing terms'
            missing_terms.each{ |term| mts.add(term, row_num, row_occ) }
            msgs = missing_terms.map{ |term| mts.message(term) }.join('; ')
            manager.add_warning!
            rep.append({row: row_num,
                        row_occ: row_occ,
                        header: 'WARN: new terms used',
                        message: msgs,
                       })
          end

          unless result.warnings.empty?
            puts 'Handling warnings'
            result.warnings.each{ |warning| manager.handle_processing_warning(rep, row_occ, warning) }
          end

          unless result.errors.empty?
            puts 'Handling errors'
            result.errors.each{ |err| manager.handle_processing_error(rep, row_occ, err) }
          end
          
          id = result.identifier
          puts "Handling record identifier: #{id}"
          if id.nil? || id.empty?
            manager.add_error!
            rep.append({row: row_num,
                        row_occ: row_occ,
                        header: 'ERR: record id',
                        message: 'Identifier for record not found or created',
                       })
            manager.add_message("No identifier value for one or more records")
          else
            rus.add(row: row_num, row_occ: row_occ, id: id)
            
            if handler.mapper[:config][:service_type] == 'relation'
              rep.append({row: row_num,
                          row_occ: row_occ,
                          header: 'INFO: relationship id',
                          message: id
                         })
            end
          end

          rcs.cache_processed(row_num, row_occ, result) if result.errors.empty?
        end

        process.save
      end

      # post-process across-batch reports
      ## unique missing terms
      if mts.total_terms > 0
        puts 'Reporting missing terms'
        mts.report_uniq_missing_terms
        manager.add_file(mts.uniq_missing_terms_file, 'text/csv')
        manager.add_message("Batch contains #{mts.total_terms} unique terms that do not exist in CollectionSpace")
        manager.add_message("Batch contains #{mts.total_term_occurrences} uses of terms that do not exist in CollectionSpace")
      end

      puts 'Finding/reporting any non-unique record ids in batch'
      rus.check_for_non_unique
      if rus.any_non_uniq
        rus.report_non_uniq
        manager.add_warning!
        manager.add_message("#{rus.non_uniq_ct} rows have non-unique identifiers")
      end

      puts 'Preparing final processing report'
      manager.finalize_processing_report(rep)

      manager.complete!
    rescue StandardError => e
      manager.exception!
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
    end
  end
end
