# frozen_string_literal: true

module WorkflowMetadata
  extend ActiveSupport::Concern
  include CableReady::Broadcaster
  CHECK_IN_INCREMENT = 5 # can checkin every 5% of the time
  CONTENT_TYPES = [
    'application/json',
    'application/vnd.ms-excel',
    'application/zip',
    'text/csv',
    'text/plain'
  ].freeze

  included do
    has_many_attached :reports
    validate :batch_has_rows
    validates :reports, content_type: CONTENT_TYPES
  end

  def all_rows_accessed?
    step_num_row == num_rows
  end

  def cancelled?
    return unless checkin?

    batch.reload.cancelled?
  end

  # this enables a throttle on the frequency of requests from jobs
  # i.e. rather than check after every row, check after N%-ish of rows
  def checkin?(force: false)
    return true if force

    (((step_num_row.to_f / num_rows) * 100).round % CHECK_IN_INCREMENT).zero?
  end

  def current_runtime
    return 0 unless started_at

    ((completed_at || Time.current.utc) - started_at).round
  end

  def done?
    done
  end

  def errors?
    step_errors.positive?
  end

  def increment_error!
    update(step_errors: step_errors + 1)
  end

  def increment_row!
    update(step_num_row: step_num_row + 1)
  end

  def increment_warning!
    update(step_warnings: step_warnings + 1)
  end

  def incremental?
    false # by default do not support incremental attachments
  end

  def limbo?
    Time.now - updated_at > 15.minutes
  end

  def num_rows
    unless name == :transferring && batch.mapper.type == 'nonhierarchicalrelationship'
      return batch.num_rows
    end

    (batch.num_rows * 2) - 1
  end

  def percentage_complete?
    return 0 if num_rows.nil? # pre validate: batch_has_rows

    (step_num_row * 100 / num_rows)
  end

  def running?
    batch.reload.running?
  end

  def update_header
    selector = '#header_' + ActionView::RecordIdentifier.dom_id(self)
    dom_html = status_renderer.render(
      partial: 'step/header', locals: { batch: batch.reload, step: self }
    )

    cable_ready['step'].morph(selector: selector, html: dom_html)
    cable_ready.broadcast
  end

  def update_progress(force: false)
    return unless checkin?(force: force)

    selector = '#progress_' + ActionView::RecordIdentifier.dom_id(self)
    dom_html = status_renderer.render(
      partial: 'step/progress', locals: { step: self }
    )

    cable_ready['step'].morph(selector: selector, html: dom_html)
    cable_ready.broadcast
  end

  def warnings?
    step_warnings.positive?
  end

  private

  def batch_has_rows
    if batch && (batch.num_rows.nil? || batch.num_rows.zero?)
      errors.add(:num_rows_error, 'batch has invalid number of rows')
    end
  end

  # Renderer for realtime updates (uses Superuser so compatible with tests)
  def status_renderer
    ApplicationController.renderer_with_signed_in_user(User.superuser)
  end
end
