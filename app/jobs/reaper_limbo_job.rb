# frozen_string_literal: true

class ReaperLimboJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false

  def perform
    # TODO:
    # - running concurrently would need lock
    # - may need to optimize (in batches)
    Batch.where(status_state: 'running').all.each do |batch|
      next if batch.job_is_active?

      step = batch.step
      next unless step.limbo?

      if step.all_rows_accessed? && !step.errors?
        step.batch.finished!
        step.update(done: true)
      else
        step.batch.failed!
        step.update(messages: step.messages.append(I18n.t('batch.step.catastrophe')))
      end

      if step.reports.count.zero?
        step.update(messages: step.messages.append(I18n.t('batch.step.no_reports')))
      end

      step.update(completed_at: Time.now.utc)
      step.update_header
      step.update_progress(force: true)
      batch.update(job_id: nil)
    end
  end
end
