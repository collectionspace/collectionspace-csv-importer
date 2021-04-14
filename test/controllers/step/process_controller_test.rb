# frozen_string_literal: true

require 'test_helper'

module Step
  class ProcessesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:superuser)
      @batch = batches(:superuser_batch) # generic batch for create
      @batch_ready = batches(:superuser_batch_preprocessed) # transition from
      @batch_processed = batches(:superuser_batch_processed) # step finished
      @batch_processed_step = step_processes(:process_superuser_batch)
      @params = {}
    end

    test 'a user can access the new process form' do
      # we transition from the previous step to this one
      assert_can_view(new_batch_step_process_path(@batch_ready))
    end

    test 'should create a process' do
      # TODO: with job
      assert_difference('Step::Process.count') do
        post batch_step_processes_path(@batch), params: { step_process: @params }
      end

      step = Step::Process.last
      assert_redirected_to batch_step_process_url(@batch, step)
    end

    test 'a user is redirected to view if the process step was already run' do
      get new_batch_step_process_path(@batch_processed)
      assert_response :redirect
    end

    test 'a user can view a process' do
      assert_can_view(
        batch_step_process_path(@batch_processed, @batch_processed_step)
      )
    end

    test 'a user can cancel a process' do
      step = step_processes(:process_superuser_batch_ready)
      step.batch.start!
      post batch_step_process_cancel_path(step.batch, step)
      assert_response :redirect
      step.reload
      assert_equal :cancelled, step.batch.current_status
    end

    test 'a user can reset a process' do
      step = step_processes(:process_superuser_batch_ready)
      step.batch.start!
      step.batch.run!
      step.batch.failed!
      assert_difference('Step::Process.count', -1) do
        post batch_step_process_reset_path(step.batch, step)
      end
      assert_response :redirect
    end
  end
end
