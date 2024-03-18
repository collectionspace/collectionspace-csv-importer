# frozen_string_literal: true

require 'test_helper'

class UserManagerPolicyTest < ActiveSupport::TestCase
  test 'manager cannot delete an admin' do
    refute_permit UserPolicy, users(:manager), users(:admin), :destroy
  end

  test 'manager can delete a manager' do
    assert_permit UserPolicy, users(:manager), users(:manager2), :destroy
  end

  test 'manager can delete a member' do
    assert_permit UserPolicy, users(:manager), users(:minion), :destroy
  end

  test 'manager cannot delete self' do
    refute_permit UserPolicy, users(:manager), users(:manager), :destroy
  end

  test 'manager cannot impersonate an admin' do
    refute_permit UserPolicy, users(:manager), users(:admin), :impersonate
  end

  test 'manager can impersonate a manager' do
    assert_permit UserPolicy, users(:manager), users(:manager2), :impersonate
  end

  test 'manager can impersonate a member' do
    assert_permit UserPolicy, users(:manager), users(:minion), :impersonate
  end

  test 'manager cannot impersonate self' do
    refute_permit UserPolicy, users(:manager), users(:manager), :impersonate
  end

  test 'manager cannot update an admin' do
    refute_permit UserPolicy, users(:manager), users(:admin2), :update
  end

  test 'manager can update a manager' do
    assert_permit UserPolicy, users(:manager), users(:manager2), :update
  end

  test 'manager can update a member' do
    assert_permit UserPolicy, users(:manager), users(:minion), :update
  end

  test 'manager can update self' do
    assert_permit UserPolicy, users(:manager), users(:manager), :update
  end

  test 'manager can update their own group' do
    assert_permit UserPolicy, users(:manager), groups(:default), :update_group
  end

  test 'manager cannot update a group they are not affiliated with' do
    refute_permit UserPolicy, users(:manager), groups(:fish), :update_group
  end

  test 'manager can update status of a user in their group' do
    assert_permit UserPolicy, users(:manager), users(:minion), :update_status
  end

  test 'manager cannot update status of a user from another group' do
    refute_permit UserPolicy, users(:manager), users(:salmon), :update_status
  end
end
