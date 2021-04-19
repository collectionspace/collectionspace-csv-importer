# frozen_string_literal: true

module Step
  class ProcessesController < Step::WorkflowController
    def new
      @step = Step::Process.new(batch: @batch)
    end

    def create
      respond_to do |format|
        @step = Step::Process.new(batch: @batch)
        if @step.update(process_params)
          format.html do
            @batch.start!
            job = ProcessJob.perform_later(@step)
            @batch.update(job_id: job.provider_job_id)
            redirect_to batch_step_process_path(
              @batch, @batch.step_process
            )
          end
        else
          format.html do
            @step = Step::Process.new(batch: @batch)
            render :new
          end
        end
      end
    end

    def show; end

    def cancel
      cancel!
      redirect_to batch_step_process_path(
        @batch, @batch.step_process
      )
    end

    def reset
      reset!
      redirect_to new_batch_step_process_path(@batch)
    end

    private

    def previous_step_complete?
      @batch.step_preprocess&.done?
    end

    def redirect_if_created
      return unless @batch.step_process

      redirect_to batch_step_process_path(
        @batch, @batch.step_process
      )
    end

    def set_batch_state
      unless previous_step_complete?
        return redirect_back(fallback_location: batches_path)
      end

      @batch.process! unless @batch.processing?
    end

    def set_step
      @step = authorize(@batch).step_process
    end

    # PARAMS
    def process_params
      {}
    end
  end
end
