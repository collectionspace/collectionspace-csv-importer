# frozen_string_literal: true

class Batch < ApplicationRecord
  include WorkflowManager
  has_one :step_preprocess, class_name: 'Step::Preprocess', dependent: :destroy
  has_one :step_process, class_name: 'Step::Process', dependent: :destroy
  belongs_to :user
  belongs_to :group
  validates :name, presence: true

  def processed?
    step_process&.done?
  end

  def preprocessed?
    step_preprocess&.done?
  end
end