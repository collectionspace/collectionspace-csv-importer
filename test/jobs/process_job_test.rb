# frozen_string_literal: true

require 'test_helper'

class ProcessJobTest < ActiveJob::TestCase
  include JobHelper

  setup do
    @process = step_processes(:process_superuser_batch_ready) # ready to go!
    attach_spreadsheet(@process, 'core-cataloging.csv')
    attach_mapper(@process, 'core-cataloging.json')
    @process.batch.start! # put the job into pending status (required transition)
  end

  test 'finishes the job' do
    assert @process.batch.pending?
    ProcessJob.perform_now(@process)
    assert_equal :finished, @process.batch.current_status
  end
end
