# frozen_string_literal: true

class StepManagerService
  attr_accessor :error_on_warning
  attr_reader :filename_base, :main_report, :files, :headers, :messages, :step, :row_results
  FILE_TYPE = 'csv'
  HEADERS = %i[row row_status message category].freeze

  def initialize(step:, error_on_warning:, save_to_file:)
    time = Time.now
    @filename_base = "#{step.batch.name.parameterize}-#{time.strftime('%F').delete('-')}-#{time.strftime('%R').delete(':')}"
    @files = []
    @messages = []
    @headers = HEADERS
    @step = step
    @error_on_warning = error_on_warning
    @save_to_file = save_to_file
    return unless @save_to_file

    @main_report = Rails.root.join('tmp', "#{@filename_base}.#{FILE_TYPE}")
    @files << { file: @main_report, type: 'csv' }
    append(@headers)
  end

  def add_error!
    step.increment_error!
    step.batch.failed! unless step.batch.failed?
  end

  # type = :tmp or :final
  # :tmp files will not be attached to the step by attach! called in finishup!
  def add_file(file, content_type, type = :final)
    return unless step.class::CONTENT_TYPES.include?(content_type)
    return unless File.file? file

    files << { file: file, content_type: content_type, type: type }
  end

  def add_message(message)
    messages << message
  end

  def add_warning!
    step.increment_warning!
    step.batch.failed! if error_on_warning && !step.batch.failed?
  end

  def attach!
    step.update(messages: messages.uniq)
    return if files.empty?

    files.each do |f|
      next if f[:type] == :tmp
      step.reports.attach(
        io: File.open(f[:file]),
        filename: File.basename(f[:file]),
        content_type: f[:content_type]
      )
    end
  end

  def cancelled?
    step.cancelled?
  end

  def complete!
    unless cancelled? || errors?
      step.batch.finished!
      step.update(done: true)
    end
    finishup!
  end

  def cut_short?
    running? || cancelled?
  end

  def errors?
    step.errors?
  end

  def exception!
    # may already be in trouble
    step.batch.failed! unless step.batch.failed?
    finishup!
  end

  def finalize_processing_report(err_warn_report_service)
    errwarn = err_warn_report_service.file
    dh = data_headers
    ah = added_headers(errwarn)

    final_report = ReportService.new(
      name: "#{@filename_base}_processing_report",
      columns: dh + ah,
      save_to_file: true
    )
    add_file(final_report.file, 'text/csv')
    
    ew = mergeable_errs_and_warnings(errwarn, ah)
    od = orig_for_merge

    od.each do |rownum, data|
      mrows = []
      if ew.key?(rownum)
        ew[rownum].each do |row_occ, mdata|
          mrows << data.merge(mdata)
        end
      else
        mrows << data
      end

      mrows.each do |mrow|
        ah.each{ |hdr| mrow[hdr] = '' unless mrow.key?(hdr) }
        final_report.append(mrow)
      end
    end
  end

  def process_transfers(type = :initial)
    processing = ReportFinder.new(batch: step.batch,
                                  step: 'process',
                                  filename_contains: 'processing_report').report
    processing.open do |csv|
      csv = CSV.open(csv.path, headers: true, encoding: 'bom|utf-8')
      loop do
        break if cancelled?

        row = csv.shift
        break unless row

        nudge! if type == :initial
        yield row.to_hash
      rescue CSV::MalformedCSVError => e
        add_error!
        log!('error', e.message)
      end
    end
  end
  
  def finalize_transfer_report(status_report_service)
    status = status_report_service.file
    processing = ReportFinder.new(batch: step.batch,
                                  step: 'process',
                                  filename_contains: 'processing_report').report
    return if processing.nil?

    processing_str = processing.download.force_encoding('utf-8')
    basecsv = CSV.parse(processing_str, headers: true)
    baseheaders = basecsv.headers

    statuscsv = CSV.parse(File.read(status), headers: true)
    statusheaders = statuscsv.headers

    final_report = ReportService.new(
      name: "#{@filename_base}_full_report",
      columns: baseheaders + statusheaders - ['row'],
      save_to_file: true
    )
    add_file(final_report.file, 'text/csv')

    m_status = mergeable_transfer_status(statuscsv)
    m_base = basecsv.map{ |r| r.to_h }
    m_base.each do |row|
      row_occ = row['INFO: rowoccurrence']
      
      merged = m_status.key?(row_occ) ? row.merge(m_status[row_occ]) : row
      statusheaders.each{ |hdr| merged[hdr] = '' unless merged.key?(hdr) }
      final_report.append(merged)
    end
  end

  def mergeable_transfer_status(transfer_status_csv)
    h = {}
    transfer_status_csv.each do |status_row|
      row_occ = status_row['row_occ']
      status_row = status_row.to_h
      status_row.delete('row')
      status_row.delete('row_occ')
      h[row_occ] = status_row unless h.key?(row_occ)
    end
    h
  end
  
  def first?
    step.step_num_row == 2 # after header
  end

  # TODO: test -- [ok, error, warning]
  # If save_to_file = true, send message for row to CSV file
  # If save_to_file = false, does nothing
  def log!(status, message, category = '')
    cat = category.empty? ? category : "#{status.upcase}: #{category}"
    append({ row: step.step_num_row, row_status: status, message: message, category: cat })
  end

  def finishup!
    step.update(completed_at: Time.now.utc)
    step.update_header # broadcast final status of step
    attach!
    remove_tmp_files!
  end

  def handle_processing_warning(report, row_occ, warning)
    category = warning[:category].to_s
    if category == 'multiple_records_found_for_term'
      m = "#{warning[:field]}: #{warning[:value]} (#{warning[:message]})".delete_prefix(': ')
    elsif warning[:field] && warning[:value]
      m = "#{warning[:field]}: #{warning[:value]}"
    elsif warning[:field] && warning[:message]
      m = "#{warning[:field]}: #{warning[:message]}"
    else
      m = warning[:message]
    end
    
    report.append({ row: step.step_num_row,
                   row_occ: row_occ,
                   header: "WARN: #{category}",
                   message: m
                  })
    add_message("One or more records has warning: #{category}")
  end

  def handle_processing_error(report, row_occ, error)
    category = error[:category].to_s
    if category == 'no_records_found_for_term'
      m = "#{error[:field]}: #{error[:value]} (#{error[:message]})".delete_prefix(': ')
    elsif error[:field] && error[:value]
      m = "#{error[:field]}: #{error[:value]}"
    else
      m = error[:message]
    end
    
    report.append({ row: step.step_num_row,
                   row_occ: row_occ,
                   header: "ERR: #{category}",
                   message: m
                  })
    add_message("One or more records has error: #{category}. These will not be transferred.")
  end

  def kickoff!
    step.batch.run! # update status to running
    step.update(started_at: Time.now.utc)
    step.update_header # broadcast current status
    nudge! # increment for header
  end

  def nudge!
    step.increment_row!
    step.update_progress
  end

  def process(type = :initial)
    step.batch.spreadsheet.open do |csv|
      csv = CSV.open(csv.path, headers: true, encoding: 'bom|utf-8')
      loop do
        break if cancelled?

        row = csv.shift
        break unless row

        nudge! if type == :initial
        yield row.to_hash
      rescue CSV::MalformedCSVError => e
        add_error!
        log!('error', e.message)
      end
    end
  end

  def row_num
    step.step_num_row
  end

  def running?
    step.running?
  end

  def warnings?
    step.warnings?
  end

  private

  def added_headers(filename)
    csv = CSV.parse(File.read(filename), headers: true)
    csv.by_col[2].uniq
  end

  def append(message)
    return unless @save_to_file

    CSV.open(main_report, 'a') do |csv|
      csv << (message.respond_to?(:key) ? message.values_at(*headers) : message.map(&:to_s))
    end
  end

  def data_headers
    row_ct = 1
    headers = []
    process(:subsequent) do |data|
      break if row_ct > 1
      headers = data.keys
      row_ct += 1
    end
    headers
  end

  def mergeable_errs_and_warnings(filename, headers)
    h = {}
    CSV.foreach(filename, headers: true) do |row|     
      h[row['row']] = {} unless h.key?(row['row'])
      h[row['row']][row['row_occ']] = {} unless h[row['row']].key?(row['row_occ'])
      headers.each do |hdr|
        h[row['row']][row['row_occ']][hdr] = [] unless h[row['row']][row['row_occ']].key?(hdr)
      end
      h[row['row']][row['row_occ']][row['header']] << row['message']
    end
    h.each do |rownum, rowocch|
      rowocch.each do |row_occ, data|
        data.transform_values!{ |val| val.join('; ') }
      end
    end
    h.transform_keys!(&:to_i)
    h
  end

  def orig_for_merge
    rowct = 2
    h = {}
    process(:subsequent) do |data|
      h[rowct] = data
      rowct += 1
    end
    h
  end

  def remove_tmp_files!
    files.each do |f|
      next unless f[:type] == :tmp
      File.delete(f[:file]) if File.exist?(f[:file])
    end
  end
end
