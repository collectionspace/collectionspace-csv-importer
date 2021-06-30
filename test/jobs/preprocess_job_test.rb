# frozen_string_literal: true

require 'test_helper'

class PreprocessJobTest < ActiveJob::TestCase
  include JobHelper

  setup do
    @preprocess = step_preprocesses(:preprocess_superuser_batch_ready) # ready to go!
    attach_spreadsheet(@preprocess, 'core-cataloging.csv')
    attach_mapper(@preprocess, 'core-cataloging.json')
    @preprocess.batch.start! # put the job into pending status (required transition)
  end

  test 'finishes the job' do
    assert @preprocess.batch.pending?
    stub_request(:get, 'https://core.dev.collectionspace.org/cspace-services/personauthorities?pgNum=0&pgSz=1&wf_deleted=false')
      .to_return(
        status: 200,
        body: File.read(Rails.root.join('test', 'fixtures', 'files', 'domain.xml')),
        headers: { 'Content-Type' => 'application/xml' }
      )
    PreprocessJob.perform_now(@preprocess)
    assert_equal :finished, @preprocess.batch.current_status
  end
end
