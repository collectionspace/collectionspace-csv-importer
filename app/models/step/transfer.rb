# frozen_string_literal: true

module Step
  class Transfer < ApplicationRecord
    include WorkflowMetadata
    belongs_to :batch
    validate :at_least_one_action?

    def incremental?
      true # we want incremental attachments for transfer jobs
    end

    def name
      :transferring
    end

    def prefix
      :tra
    end

    private

    # TODO: enforce permutations in model? (currently in ui)
    def at_least_one_action?
      return if action_create || action_delete || action_update

      errors.add(
        :action_required,
        'Transfer requires at least one action (create, update, delete)'
      )
    end
  end
end
