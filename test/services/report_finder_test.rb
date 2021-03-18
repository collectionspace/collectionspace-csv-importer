# frozen_string_literal: true

require 'test_helper'

class ReportFinderTest < ActiveSupport::TestCase
  setup do
    @s = step_processes(:process_superuser_batch_ready)
    @s.batch.start! # set the batch status to :pending (i.e. job enqueued)
    @step = StepManagerService.new(step: @s, error_on_warning: false, save_to_file: false)
    @step.kickoff!
    @step.add_file(
      Rails.root.join('test', 'fixtures', 'files', 'core-cataloging.csv'), 'text/csv'
    )
    @step.attach!
  end

  test 'can return specified blob' do
    rep = ReportFinder.new(batch: @s.batch.id, step: 'process', filename_contains: 'core-cat').report
    assert_instance_of(ActiveStorage::Blob, rep)
  end

  test 'can return nil if no matching report is found' do
    rep = ReportFinder.new(batch: @s.batch.id, step: 'process', filename_contains: 'tmp').report
    assert_nil(rep)
  end
end
