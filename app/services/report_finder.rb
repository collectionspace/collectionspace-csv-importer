# frozen_string_literal: true

# provides easy access to step report files between different steps
class ReportFinder
  def initialize(batch:, step:, filename_contains:)
    @batch = batch
    @step = "Step::#{step.capitalize}".constantize
    @contains = filename_contains
  end

  def report
    step = @step.where(batch_id: @batch)
    return nil if step.empty?

    step = step.first
    return nil unless step.reports.attached?

    reports = step.reports.blobs
    report = reports.select{ |r| r.filename.to_s[@contains] }
    return nil if report.empty?
    
    report.first
  end
end
