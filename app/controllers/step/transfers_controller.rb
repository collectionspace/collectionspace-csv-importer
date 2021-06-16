# frozen_string_literal: true

module Step
  class TransfersController < Step::WorkflowController
    before_action :set_selected, only: %i[new show]

    def new
      @step = Step::Transfer.new(batch: @batch)
    end

    def create
      respond_to do |format|
        @step = Step::Transfer.new(batch: @batch)
        if @step.update(transfer_params)
          format.html do
            @batch.start!
            job = TransferJob.perform_later(@step)
            @batch.update(job_id: job.provider_job_id)
            redirect_to batch_step_transfer_path(
              @batch, @batch.step_transfer
            )
          end
        else
          format.html do
            redirect_to new_batch_step_transfer_path(@batch),
                        alert: error_messages(@step.errors)
          end
        end
      end
    end

    def show; end

    def cancel
      cancel!
      redirect_to batch_step_transfer_path(
        @batch, @batch.step_transfer
      )
    end

    def reset
      reset!
      redirect_to new_batch_step_transfer_path(@batch)
    end

    private

    def previous_step_complete?
      @batch.step_process&.done?
    end

    def redirect_if_created
      return unless @batch.step_transfer

      redirect_to batch_step_transfer_path(
        @batch, @batch.step_transfer
      )
    end

    def set_batch_state
      unless previous_step_complete?
        return redirect_back(fallback_location: batches_path)
      end

      @batch.transfer! unless @batch.transferring?
    end

    def set_selected
      # state for create / delete / update
      session[@batch.fingerprint] ||= { create: true, update: true, delete: false }
      @selected = session[@batch.fingerprint]
    end

    def set_step
      @step = authorize(@batch).step_transfer
    end

    # PARAMS
    def transfer_params
      params.require(:step_transfer).permit(:action_create, :action_update, :action_delete)
    end
  end
end
