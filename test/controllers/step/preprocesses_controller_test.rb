# frozen_string_literal: true

require 'test_helper'

module Step
  class PreprocessesControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    setup do
      sign_in users(:superuser)
      @batch = batches(:superuser_batch)
      @batch_preprocessed = batches(:superuser_batch_preprocessed)
      @batch_preprocessed_step = step_preprocesses(:preprocess_superuser_batch)
      @batch.mapper.config.attach(
        io: File.open(Rails.root.join('test', 'fixtures', 'files',
                                      'core-cataloging.json')),
        filename: 'core-cataloging.json',
        content_type: 'application/json',
        identify: false
      )
      # @valid_params = {
      #   step_preprocess: {
      #     message: 'preprocess'
      #   }
      # }
    end

    test 'a user can access the new preprocess form' do
      assert_can_view(new_batch_step_preprocess_path(@batch))
    end

    test 'should create a preprocess' do
      assert_difference('Step::Preprocess.count') do
        assert_enqueued_with(job: PreprocessJob) do
          post batch_step_preprocesses_path(@batch), params: {} # @valid_params
        end
      end

      perform_enqueued_jobs
      assert_performed_jobs 2 # storage analysis + preprocess
      assert_redirected_to batch_step_preprocess_url(@batch, Step::Preprocess.last)
    end

    test 'a user is redirected to view if the preprocess step was already run' do
      get new_batch_step_preprocess_path(@batch_preprocessed)
      assert_response :redirect
    end

    test 'a user can view a preprocess' do
      assert_can_view(
        batch_step_preprocess_path(
          @batch_preprocessed,
          @batch_preprocessed_step
        )
      )
    end

    test 'a user can cancel a preprocess' do
      step = step_preprocesses(:preprocess_superuser_batch_ready)
      step.batch.start!
      post batch_step_preprocess_cancel_path(step.batch, step)
      assert_response :redirect
      step.reload
      assert_equal :cancelled, step.batch.current_status
    end

    test 'a user can reset a preprocess' do
      step = step_preprocesses(:preprocess_superuser_batch_ready)
      step.batch.start!
      step.batch.run!
      step.batch.cancel!
      assert_difference('Step::Preprocess.count', -1) do
        post batch_step_preprocess_reset_path(step.batch, step)
      end
      assert_response :redirect
    end
  end
end
