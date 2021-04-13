# frozen_string_literal: true

module WorkflowManager
  extend ActiveSupport::Concern

  included do
    include AASM

    def previous_step_done?
      finished?
    end

    def current_step
      aasm(:step).current_state
    end

    def current_step?(step)
      current_step == step
    end

    def current_status
      aasm(:status).current_state
    end

    # we transitioned beyond run!
    def ran?
      failed? || finished?
    end

    aasm(:step, column: 'step_state') do
      state :new, initial: true, display: 'new'
      state :preprocessing, display: 'preprocess'
      state :processing, display: 'process'
      state :transferring, display: 'transfer'
      state :archiving, display: 'archive'

      event :preprocess do
        transitions from: :new, to: :preprocessing
      end

      event :process, binding_event: :next_step do
        transitions from: :preprocessing, to: :processing, if: :previous_step_done?
      end

      event :transfer, binding_event: :next_step do
        # transitions from: :processing, to: :deleting # if: [type] delete && :previous_step_done?
        transitions from: :processing, to: :transferring, if: :previous_step_done?
      end

      event :archive, binding_event: :next_step do
        transitions from: :transferring, to: :archiving, if: :previous_step_done?
      end
    end

    aasm(:status, column: 'status_state') do
      state :ready, initial: true
      state :pending
      state :running
      state :cancelled
      state :failed
      state :finished

      event :start do
        transitions from: :ready, to: :pending
      end

      event :run do
        transitions from: :pending, to: :running
      end

      event :cancel do
        transitions from: %i[pending running], to: :cancelled
      end

      event :failed do
        transitions from: :running, to: :failed
      end

      event :retry do
        transitions from: %i[cancelled failed], to: :ready
      end

      event :finished do
        transitions from: :running, to: :finished
      end

      event :next_step do
        transitions from: :finished, to: :ready
      end
    end
  end
end
