# frozen_string_literal: true

require 'test_helper'

class StepManagerServiceTest < ActiveSupport::TestCase
  setup do
    @pps = step_preprocesses(:preprocess_superuser_batch_ready)
    @pps.batch.start! # set the batch status to :pending (i.e. job enqueued)
    @ppstep = StepManagerService.new(step: @pps, error_on_warning: false, save_to_file: false)
    @ppstep.kickoff!

    @s = step_processes(:process_superuser_batch_ready)
    @s.batch.start! # set the batch status to :pending (i.e. job enqueued)
    @step = StepManagerService.new(step: @s, error_on_warning: false, save_to_file: false)
    @step.kickoff!
end

  test 'cannot add files to preprocessing step' do
    assert_equal 0, @step.files.size
    @ppstep.add_file(
      Rails.root.join('test', 'fixtures', 'files', 'core-cataloging.csv'), 'text/csv'
    )
    assert_equal 0, @step.files.size
  end
  
  test 'can add files to another step' do
    assert_equal 0, @step.files.size
    @step.add_file(
      Rails.root.join('test', 'fixtures', 'files', 'core-cataloging.csv'), 'text/csv'
    )
    @step.add_file(
      Rails.root.join('test', 'fixtures', 'files', 'tempfile.csv'), 'text/csv', :tmp
    )
    assert_equal 2, @step.files.size
  end

  test 'can attach non-temp files to a step' do
    @step = StepManagerService.new(step: @s, error_on_warning: false, save_to_file: true)
    @step.attach!
    assert 1, @step.step.reports.count
    FileUtils.rm Dir.glob(Rails.root.join('tmp', '*.csv'))
  end

  test 'will not add a non-file to a step' do
    assert_equal 0, @step.files.size
    @step.add_file(Rails.root.join('test/'), 'text/csv')
    assert_equal 0, @step.files.size
  end

  test 'will not add an unrecognized file (by type) to a step' do
    assert_equal 0, @step.files.size
    @step.add_file(Rails.root.join('README.md'), 'text/markdown')
    assert_equal 0, @step.files.size
  end

  test 'can add a message to a step' do
    assert_equal 0, @step.messages.count
    @step.add_message('Hello!')
    assert_equal 1, @step.messages.count
    @step.attach!
    assert_equal 'Hello!', @step.step.messages[0]
  end

  test 'can add an error to a step' do
    assert_equal 0, @s.step_warnings
    @step.add_error!
    assert_equal 1, @s.step_errors
    assert_equal :failed, @s.batch.current_status
  end

  test 'can add a warning to a step (and not fail)' do
    @step.error_on_warning = false # just being clear on state
    assert_equal 0, @s.step_warnings
    @step.add_warning!
    assert_equal 1, @s.step_warnings
    assert_equal :running, @s.batch.current_status
  end

  test 'can add a warning to a step and set status to failed' do
    @step.error_on_warning = true
    @step.add_warning!
    assert_equal :failed, @s.batch.current_status
  end

  test 'can identify a cancelled step' do
    @s.batch.cancel!
    assert @step.cancelled?
  end

  test 'can cut short a step when already running' do
    assert @step.cut_short?
  end

  test 'can cut short a step when cancelled' do
    @s.batch.cancel!
    assert @step.cut_short?
  end

  test 'can complete a step, without errors is success' do
    @step.complete!
    assert @s.batch.finished?
    assert @s.done?
    assert :finished, @s.batch.current_status
    assert_not_nil @s.completed_at
  end

  test 'can complete a step, with errors is a fail' do
    @step.add_error!
    @step.complete!
    assert @s.batch.failed?
    refute @s.done?
    assert :failed, @s.batch.current_status
    assert_not_nil @s.completed_at
  end

  test 'can complete a step, when cancelled is cancelled' do
    @s.batch.cancel!
    @step.complete!
    assert @s.batch.cancelled?
    refute @s.done?
    assert :cancelled, @s.batch.current_status
    assert_not_nil @s.completed_at
  end

  test 'can finish up after an exception' do
    @step.exception!
    assert :failed, @s.batch.current_status
    assert_not_nil @s.completed_at
  end

  test 'can kick off a step' do
    assert_equal :running, @s.batch.current_status
    assert_not_nil @s.started_at
  end

  test 'can nudge a step' do
    assert_equal 1, @s.step_num_row
    @step.nudge!
    assert_equal 2, @s.step_num_row
  end

  test 'can identify the first row of data' do
    assert_equal 1, @s.step_num_row
    refute @step.first? # header row
    @step.nudge!
    assert_equal 2, @s.step_num_row
    assert @step.first?
    @step.nudge!
    assert_equal 3, @s.step_num_row
    refute @step.first? # header row
  end
end
