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
    stub_request(:get, "https://core.dev.collectionspace.org/cspace-services/collectionobjects?as=collectionobjects_common:objectNumber%20=%20'1'&pgSz=25&sortBy=collectionspace_core:updatedAt%20DESC&wf_deleted=false")
      .to_return(status: 200, body: '', headers: {})

    stub_request(:get, 'https://core.dev.collectionspace.org/cspace-services/personauthorities?pgNum=0&pgSz=1&wf_deleted=false')
      .to_return(status: 200, body: '', headers: {})

    ProcessJob.perform_now(@process)
    assert_equal :finished, @process.batch.current_status
  end
end
