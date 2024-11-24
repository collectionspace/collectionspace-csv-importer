# frozen_string_literal: true

require 'test_helper'

class ProcessingReportFinalizerServiceTest < ActiveSupport::TestCase
  # @param orig_csv [String] file name; file should be in test/fixtures/files
  # @param merge_csv [String] file name; file should be in test/fixtures/files
  # @param expected [String] file name; file should be in test/fixtures/files
  def run_test(batch: batches(:superuser_batch), orig_csv:, merge_csv:,
              expected:)
    @batch = batches(:superuser_batch)
    @batch.spreadsheet.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', orig_csv)),
      filename: orig_csv,
      content_type: 'text/csv',
      identify: false
    )
    @service = ProcessingReportFinalizerService.new(
      base_name: "batchname",
      orig_file: @batch.spreadsheet,
      merge_file_path: File.join(Rails.root, 'test', 'fixtures', 'files',
                                 merge_csv)
    )
    @reportpath = @service.send(:report).file.to_s
    @expectpath = File.join(Rails.root, 'test', 'fixtures', 'files', expected)
  end

  teardown do
    return unless File.exist?(@reportpath)

    File.delete(@reportpath)
  end

  test 'can produce report for batch with no errors' do
    run_test(batch: batches(:superuser_batch_processed),
             orig_csv: "core-cataloging.csv",
             merge_csv: "core-cataloging_merge_data.csv",
             expected: "core_cataloging_processing_report.csv"
            )
    @service.call
    assert_equal(File.read(@expectpath), File.read(@reportpath))

  end

  test 'can produce report for batch with missing terms' do
    run_test(batch: batches(:superuser_batch_processed),
             orig_csv: "missing_terms.csv",
             merge_csv: "missing_terms_merge_data.csv",
             expected: "missing_terms_processing_report.csv"
            )
    @service.call
    assert_equal(File.read(@expectpath), File.read(@reportpath))

  end

  test 'can produce report for batch with duplicate ids' do
    run_test(batch: batches(:superuser_batch_processed),
             orig_csv: "core-cat-duplicate-ids.csv",
             merge_csv: "core-cat-duplicate-ids_merge_data.csv",
             expected: "core-cat-duplicate-ids_processing_report.csv"
            )
    @service.call
    assert_equal(File.read(@expectpath), File.read(@reportpath))

  end

  test 'can produce report for nonhierarchicalrelationship batch' do
    run_test(batch: batches(:nhr_batch_transferring),
             orig_csv: "nonhierrel.csv",
             merge_csv: "nonhierrel_merge_data.csv",
             expected: "nonhierrel_processing_report.csv"
            )
    @service.call
    assert_equal(File.read(@expectpath), File.read(@reportpath))
  end
end
