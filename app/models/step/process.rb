# frozen_string_literal: true

module Step
  class Process < ApplicationRecord
    include ConnectionStatus
    include WorkflowMetadata
    belongs_to :batch
    validate :connection_is_active?

    def name
      :processing
    end

    def prefix
      :pro
    end
  end
end
