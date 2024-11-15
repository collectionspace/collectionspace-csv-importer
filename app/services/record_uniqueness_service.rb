# frozen_string_literal: true

# Gathers record identifiers returned row-by-row by the process_job, and
# keeps batch-level track of any duplicates for reporting
class RecordUniquenessService
  def initialize(log_report:)
    @report = log_report
    @ids = {}
  end

  def add(row_num:, row_occ:, rec_id:)
    @ids[rec_id] = [] unless @ids.key?(rec_id)
    @ids[rec_id] << [row_num, row_occ]
  end

  # writes to main error/warnings report so that info can be merged into final report
  def report_non_unique
    non_unique.each do |id, rowlist|
      rowlist.each { |row| report_non_unique_row(id, row) }
    end
  end

  def non_unique
    @non_unique ||= @ids.select{ |id, rowoccs| rowoccs.length > 1 }
  end

  def any_non_unique? = !non_unique.empty?

  def non_unique_count
    return 0 unless any_non_unique?

    non_unique.map { |_id, vals| vals.length }
      .sum
  end

  private

  def duplicate_rows_for(id)
    @ids[id].map { |rowinfo| rowinfo[1] }.join(', ')
  end

  def report_non_unique_row(id, rowinfo)
      @report.append({
        row: rowinfo[0],
        row_occ: rowinfo[1],
        header: "WARN: duplicate record ids",
        message: "Duplicate ID \"#{id}\" in rows: #{duplicate_rows_for(id)}"
      })
  end
end
