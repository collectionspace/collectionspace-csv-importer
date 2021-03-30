# frozen_string_literal: true

require 'test_helper'

class ReportServiceTest < ActiveSupport::TestCase
  setup do
    @step = step_processes(:process_superuser_batch_ready)
    @step.batch.start! # set the batch status to :pending (i.e. job enqueued)
    @stepman = StepManagerService.new(step: @step, error_on_warning: false, save_to_file: false)
    @stepman.kickoff!

    @reportsvc = ReportService.new(name: 'testreport',
                                   columns: %i[header1 header2 header3],
                                   save_to_file: true)
  end

  test 'can create file that can be added to StepManagerService' do
    @stepman.add_file(@reportsvc.file, 'text/csv')
    assert_equal(1, @stepman.files.size)
  end
end
