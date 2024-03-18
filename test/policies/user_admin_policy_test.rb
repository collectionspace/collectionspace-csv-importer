# frozen_string_literal: true

require 'test_helper'

class UserAdminPolicyTest < ActiveSupport::TestCase
  test 'admin cannot delete the superuser' do
    refute_permit UserPolicy, users(:admin), users(:superuser), :destroy
  end

  test 'admin can delete another admin' do
    assert_permit UserPolicy, users(:admin), users(:admin2), :destroy
  end

  test 'admin can delete a manager' do
    assert_permit UserPolicy, users(:admin), users(:manager), :destroy
  end

  test 'admin can delete a member' do
    assert_permit UserPolicy, users(:admin), users(:minion), :destroy
  end

  test 'admin cannot delete self' do
    refute_permit UserPolicy, users(:admin), users(:admin), :destroy
  end

  test 'admin cannot impersonate the superuser' do
    refute_permit UserPolicy, users(:admin), users(:superuser), :impersonate
  end

  test 'admin can impersonate another admin' do
    assert_permit UserPolicy, users(:admin), users(:admin2), :impersonate
  end

  test 'admin can impersonate a manager' do
    assert_permit UserPolicy, users(:admin), users(:manager), :impersonate
  end

  test 'admin can impersonate a member' do
    assert_permit UserPolicy, users(:admin), users(:minion), :impersonate
  end

  test 'admin cannot impersonate self' do
    refute_permit UserPolicy, users(:admin), users(:admin), :impersonate
  end

  test 'admin cannot update the superuser' do
    refute_permit UserPolicy, users(:admin), users(:superuser), :update
  end

  test 'admin can update another admin' do
    assert_permit UserPolicy, users(:admin), users(:admin2), :update
  end

  test 'admin can update a manager' do
    assert_permit UserPolicy, users(:admin), users(:manager), :update
  end

  test 'admin can update a member' do
    assert_permit UserPolicy, users(:admin), users(:minion), :update
  end

  test 'admin can update self' do
    assert_permit UserPolicy, users(:admin), users(:admin), :update
  end

  test 'admin can update status (inline) of another user' do
    assert_permit UserPolicy, users(:admin), users(:manager), :update_status
  end

  test 'admin cannot update status (inline) of superuser or self' do
    %i[superuser admin].each do |user|
      refute_permit UserPolicy, users(:admin), users(user), :update_status
    end
  end
end
