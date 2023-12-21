# frozen_string_literal: true

module Step
  class ArchivesController < Step::WorkflowController
    def new
      @step = Step::Archive.new(batch: @batch)
    end

    def create
      respond_to do |format|
        @step = Step::Archive.new(batch: @batch)
        if @step.update(archive_params)
          format.html do
            @batch.start!
            ArchiveJob.perform_now(@step) # foreground this one for now
            @batch.update(job_id: nil)
            redirect_to batch_step_archive_path(
              @batch, @batch.step_archive
            )
          end
        else
          format.html do
            flash.now[:alert] = error_messages(@step.errors)
            @step = Step::Archive.new(batch: @batch)
            render :new
          end
        end
      end
    end

    def show; end

    def cancel
      cancel!
      redirect_to batch_step_archive_path(
        @batch, @batch.step_archive
      )
    end

    def reset
      reset!
      redirect_to new_batch_step_archive_path(@batch)
    end

    private

    def previous_step_complete?
      @batch.step_transfer&.done?
    end

    def redirect_if_created
      return unless @batch.step_archive

      redirect_to batch_step_archive_path(
        @batch, @batch.step_archive
      )
    end

    def set_batch_state
      unless previous_step_complete?
        return redirect_back(fallback_location: batches_path)
      end

      @batch.archive! unless @batch.archiving?
    end

    def set_step
      @step = authorize(@batch).step_archive
    end

    # PARAMS
    def archive_params
      {}
    end
  end
end
