# frozen_string_literal: true

# gathers record identifiers returned row-by-row by the process_job, and
# keeps batch-level track of any duplicates for reporting
class RecordUniquenessService
  attr_reader :any_non_uniq, :non_uniq_ct
  def initialize(batch:, log_report:)
    @report = log_report
    @ids = {}
  end

  def add(row:, row_occ:, id:)
    row_id = "#{row}.#{row_occ}"
    @ids[id] = [] unless @ids.key?(id)
    @ids[id] << row_id
  end

  # writes to main error/warnings report so that info can be merged into final report
  def report_non_uniq
    @non_unique.each do |id, rownums|
      rownums.each do |rownum|
        @report.append({
          row: rownum,
          row_status: 'warning',
          message: "Duplicate ID #{id} in batch: rows #{rownums.join(', ')}",
          category: 'duplicate records'
        })
      end
    end
  end


  def check_for_non_unique
    return @non_unique if @non_unique
    @non_unique = @ids.delete_if{ |id, rownums| rownums.length == 1 }
    @any_non_uniq = @non_unique.empty? ? false : true
    @non_uniq_ct = @non_unique.empty? ? 0 : count_non_uniq
  end

  private

  def count_non_uniq
    @non_unique.values.flatten.length
  end
end
