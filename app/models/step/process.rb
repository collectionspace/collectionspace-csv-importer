# frozen_string_literal: true

module Step
  class Process < ApplicationRecord
    include WorkflowMetadata
    belongs_to :batch

    def name
      :processing
    end

    def prefix
      :pro
    end
  end
end
