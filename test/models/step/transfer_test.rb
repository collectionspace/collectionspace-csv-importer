# frozen_string_literal: true

require 'test_helper'

module Step
  class TransferTest < ActiveSupport::TestCase
    setup do
      @params = {
        batch_id: batches(:superuser_batch).id
      }
    end

    test 'cannot create a transfer step without a batch' do
      @params.delete(:batch_id)
      refute Step::Transfer.new(@params).valid?
    end

    test 'cannot create a transfer step without an action' do
      refute Step::Transfer.new(@params).valid?
    end

    # TODO: make this conditional validation on batch state
    test 'can create a transfer step with actions' do
      %i[action_create action_delete action_update].each do |action|
        params = @params.dup
        params[action] = true
        assert Step::Transfer.new(params).valid?
      end
    end
  end
end
