# frozen_string_literal: true

class TransferJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false
  ERRORS = [:message].freeze

  def perform(transfer)
    manager = StepManagerService.new(
      step: transfer, error_on_warning: false, save_to_file: false
    )
    return if manager.cut_short?

    manager.kickoff!

    begin
      rcs = RecordCacheService.new(batch: transfer.batch)
      rts = RecordTransferService.new(transfer: transfer)

      # create temporary status report to later be merged with previous
      #  processing step report
      rep = ReportService.new(name: "#{manager.filename_base}_transfer_status",
                              columns: %i[row row_occ XFER_status XFER_message XFER_uri],
                              save_to_file: true)
      manager.add_file(rep.file, 'text/csv', :tmp)

      manager.process_transfers do |data|
        rownum = data['INFO: rownum']
        row_occ = data['INFO: rowoccurrence']
        
        cached_data = rcs.retrieve_cached(rownum, row_occ)

        # can't transfer if there's no cached payload and other info
        # TODO: figure out how to make this more resilient by re-processing if there's no cached value
        unless cached_data
          rep.append({ row: rownum,
                       row_occ: row_occ,
                      XFER_status: 'failure',
                      XFER_message: 'No processed data found. Processed record may have expired from cache, in which case you need to start over with the batch.',
                      XFER_uri: ''
                     })
          manager.add_warning!
          manager.add_message('At least one record was not transferred because no XML payload was available to transfer')
          next
        end

        result = rts.transfer_record(cached_data)

        if result.success?
          rep.append({ row: rownum,
                      row_occ: row_occ,
                      XFER_status: 'success',
                      XFER_message: result.action,
                      XFER_uri: result.uri
                     })
        else
          rep.append({ row: rownum,
                      row_occ: row_occ,
                      XFER_status: 'failure',
                      XFER_message: result.message,
                      XFER_uri: ''
                     })
          manager.add_warning!
          manager.add_message('Some records did not transfer. See CSV report for details')
        end
      end

      puts 'Preparing final transfer report'
      manager.finalize_transfer_report(rep)

      manager.complete!
    rescue StandardError => e
      manager.exception!
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
    end
  end
end
