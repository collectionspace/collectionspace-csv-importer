# frozen_string_literal: true

require 'test_helper'

class UserMemberPolicyTest < ActiveSupport::TestCase
  test 'member cannot delete an admin' do
    refute_permit UserPolicy, users(:minion), users(:admin), :destroy
  end

  test 'member cannot delete a manager' do
    refute_permit UserPolicy, users(:minion), users(:manager2), :destroy
  end

  test 'member cannot delete a member' do
    refute_permit UserPolicy, users(:minion), users(:minion), :destroy
  end

  test 'member cannot delete self' do
    refute_permit UserPolicy, users(:minion), users(:minion), :destroy
  end

  test 'member cannot impersonate an admin' do
    refute_permit UserPolicy, users(:minion), users(:admin), :impersonate
  end

  test 'member cannot impersonate a manager' do
    refute_permit UserPolicy, users(:minion), users(:manager), :impersonate
  end

  test 'member cannot impersonate a member' do
    refute_permit UserPolicy, users(:minion), users(:outcast), :impersonate
  end

  test 'member cannot impersonate self' do
    refute_permit UserPolicy, users(:minion), users(:minion), :impersonate
  end

  test 'member cannot update an admin' do
    refute_permit UserPolicy, users(:minion), users(:admin2), :update
  end

  test 'member cannot update a manager' do
    refute_permit UserPolicy, users(:minion), users(:manager), :update
  end

  test 'member cannot update another member' do
    refute_permit UserPolicy, users(:minion), users(:outcast), :update
  end

  test 'member can update self' do
    assert_permit UserPolicy, users(:minion), users(:minion), :update
  end

  test 'member cannot update their own group' do
    refute_permit UserPolicy, users(:minion), groups(:default), :update_group
  end

  test 'member cannot update a group they are not affiliated with' do
    refute_permit UserPolicy, users(:minion), groups(:fish), :update_group
  end

  test 'member cannot update status of another user' do
    refute_permit UserPolicy, users(:minion), users(:carrot), :update_status
  end
end
