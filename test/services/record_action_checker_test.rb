# frozen_string_literal: true

require 'test_helper'

class RecordActionCheckerTest < ActiveSupport::TestCase
  setup do
    @delete_step = Object.new
    def @delete_step.action_delete
      true
    end
    def @delete_step.action_create
      false
    end
    def @delete_step.action_update
      false
    end
    
    @create_step = Object.new
    def @create_step.action_delete
      false
    end
    def @create_step.action_create
      true
    end
    def @create_step.action_update
      false
    end

    @update_step = Object.new
    def @update_step.action_delete
      false
    end
    def @update_step.action_create
      false
    end
    def @update_step.action_update
      true
    end
  end

  test 'can determine action for new record with create new records checked' do
    rac = RecordActionChecker.new(:new, @create_step)
    assert(rac.createable?)
    refute(rac.deleteable?)
    refute(rac.updateable?)
  end

  test 'can determine action for new record with update existing records checked' do
    rac = RecordActionChecker.new(:new, @update_step)
    refute(rac.createable?)
    refute(rac.deleteable?)
    refute(rac.updateable?)
  end

  test 'can determine action for new record with delete records checked' do
    rac = RecordActionChecker.new(:new, @delete_step)
    refute(rac.createable?)
    refute(rac.deleteable?)
    refute(rac.updateable?)
  end

  test 'can determine action for existing record with create existing records checked' do
    rac = RecordActionChecker.new(:existing, @create_step)
    refute(rac.createable?)
    refute(rac.deleteable?)
    refute(rac.updateable?)
  end

  test 'can determine action for existing record with update existing records checked' do
    rac = RecordActionChecker.new(:existing, @update_step)
    refute(rac.createable?)
    refute(rac.deleteable?)
    assert(rac.updateable?)
  end

  test 'can determine action for existing record with delete records checked' do
    rac = RecordActionChecker.new(:existing, @delete_step)
    refute(rac.createable?)
    assert(rac.deleteable?)
    refute(rac.updateable?)
  end
end
