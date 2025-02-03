# frozen_string_literal: true

module Step
  class Preprocess < ApplicationRecord
    include ConnectionStatus
    include WorkflowMetadata
    belongs_to :batch
    validate :connection_is_active?

    def name
      :preprocessing
    end

    def prefix
      :pre
    end
  end
end
