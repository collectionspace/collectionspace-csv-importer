# frozen_string_literal: true

require 'test_helper'

class RecordActionCheckerTest < ActiveSupport::TestCase
  setup do
    @delete_step = Minitest::Mock.new
    @delete_step.expect :action_delete, true
    @delete_step.expect :action_create, false
    @delete_step.expect :action_update, false

    @create_step = Minitest::Mock.new
    @create_step.expect :action_delete, false
    @create_step.expect :action_create, true
    @create_step.expect :action_update, false

    @update_step = Minitest::Mock.new
    @update_step.expect :action_delete, false
    @update_step.expect :action_create, false
    @update_step.expect :action_update, true
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
