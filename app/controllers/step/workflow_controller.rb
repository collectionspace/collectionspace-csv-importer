# frozen_string_literal: true

module Step
  class WorkflowController < ApplicationController
    protect_from_forgery except: %i[cancel reset] # tokens regenerated [CR]
    before_action :set_batch, except: :create
    before_action :set_batch_for_create, only: :create
    before_action :redirect_if_created, only: :new
    before_action :set_batch_state, only: :new
    before_action :set_step, only: %i[show reset]
    # before_action :set_batch_failed_if_running_and_not_active, only: %i[show] # TODO: ECS testing

    def cancel!
      authorize @batch, policy_class: Step::Policy
      ApplicationJob.cancel!(@batch.job_id)
      @batch.cancel!
      @batch.update(job_id: nil)
    end

    def reset!
      authorize @batch, policy_class: Step::Policy
      @step.destroy
      @batch.retry!
    end

    def previous_step_complete?
      raise NotImplementedError
    end

    def set_batch
      @batch = authorize Batch.find(params[:batch_id])
    end

    def set_batch_failed_if_running_and_not_active
      # TODO: switchup the handling of this
      # LT it will be better to reap jobs in limbo
      return unless @batch.running?

      @batch.failed! if !@batch.job_is_active? && @batch.reload.running?

      return unless @batch.failed?

      @batch.update(job_id: nil)
      @step.update(messages: [I18n.t('batch.step.catastrophe')])
    end

    def set_batch_for_create
      @batch = authorize Batch.find(params[:batch_id]), policy_class: Step::Policy
    end

    # methods to be implemented in subclasses

    def redirect_if_created
      raise NotImplementedError
    end

    def set_batch_state
      raise NotImplementedError
    end

    def set_step
      raise NotImplementedError
    end
  end
end
