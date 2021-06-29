# frozen_string_literal: true

require 'test_helper'

class WorkflowMetadataTest < ActiveSupport::TestCase
  setup do
    @step = step_preprocesses(:preprocess_superuser_batch_ready)
  end

  test 'by default has no errors or warnings' do
    assert_not @step.errors?
    assert_not @step.warnings?
  end

  test 'can increment the step row count' do
    rows = @step.step_num_row
    @step.increment_row!
    assert_equal rows + 1, @step.step_num_row
  end

  test 'can approve status checkins' do
    checkins = [
      { batch: 10, step: 5, checkin: true },
      { batch: 100, step: 42, checkin: false },
      { batch: 100, step: 45, checkin: true },
      { batch: 102, step: 40, checkin: false },
      { batch: 102, step: 41, checkin: true },
      { batch: 1000, step: 45, checkin: true },
      { batch: 1000, step: 50, checkin: true },
      { batch: 10_000, step: 50, checkin: false },
      { batch: 10_000, step: 500, checkin: true },
    ]
    checkins.each do |checkin|
      @step.batch.update(num_rows: checkin[:batch])
      @step.update(step_num_row: checkin[:step])
      checkin[:checkin] ? assert(@step.checkin?) : refute(@step.checkin?)
    end
  end

  test 'can calculate the % complete' do
    @step.batch.update(num_rows: 10)
    @step.update(step_num_row: 7)
    assert_equal 70, @step.percentage_complete?

    nhr_xfer_step = step_transfers(:transfer_nhr_batch_ready)
    nhr_xfer_step.batch.update(num_rows: 10)
    nhr_xfer_step.update(step_num_row: 19)
    assert_equal 100, nhr_xfer_step.percentage_complete?
  end
end
