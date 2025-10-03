# frozen_string_literal: true

class ProcessingReportFinalizerService
  class << self
    # @param base_name [String]
    # @param orig_file_path [String]
    # @param merge_file_path [String]
    def call(...)
      new(...).call
    end
  end

  # @param base_name [String]
  # @param orig_file [ActiveStorage::Attached:One]
  # @param merge_file_path [String] to the tmp file to which each individual
  #   info, warning, or error for each row has been written
  def initialize(base_name:, orig_file:, merge_file_path:)
    @orig_file = orig_file
    @merge_file_path = merge_file_path
    @report = ReportService.new(
      name: "#{base_name}_processing_report",
      columns: data_headers + added_headers,
      save_to_file: true
    )
  end

  def call
    orig_data { |row| finalize_row(row) }

    report.file
  end

  private

  attr_reader :orig_file, :merge_file_path, :report

  def data_headers
    orig_file.open do |storage|
      @data_headers ||= CSV.parse_line(
        File.read(storage.path, encoding: 'bom|utf-8'),
        headers: true
      ).headers
    end
  end

  def added_headers
    @added_headers ||= merge_data.by_col['header'].uniq
  end

  def merge_data
    @merge_data ||= CSV.parse(File.open(merge_file_path), headers: true)
  end

  def orig_data
    orig_file.open do |storage|
      csv = CSV.open(
        storage.path,
        headers: true,
        encoding: 'bom|utf-8'
      )
      rownum = 2
      loop do
        row = csv.shift
        break unless row

        yield row.to_hash.merge({ 'row_num' => rownum })
        rownum += 1
      end
    end
  end

  def finalize_row(row)
    merge_data_for(row).each { |mrow| write_finalized_row(row, mrow) }
  end

  def write_finalized_row(row, merge_row)
    report.append(row.merge(merge_row))
  end

  def merge_data_for(row)
    result = {}
    merge_data.each_with_index do |mdrow, idx|
      next unless mdrow["row"] == row["row_num"].to_s

      result[idx] = mdrow
    end

    result.keys.reverse.each { |idx| merge_data.delete(idx) }
    result.values
      .group_by { |mdrow| mdrow["row_occ"] }
      .values
      .map { |rowgrp| merge_row(rowgrp) }
  end

  def merge_row(merge_rows)
    merge_rows.map { |mdrow| [mdrow["header"], mdrow["message"]] }
      .to_h
  end
end
