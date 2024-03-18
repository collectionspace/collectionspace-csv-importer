# frozen_string_literal: true

require 'test_helper'

class GroupPolicyTest < ActiveSupport::TestCase
  test 'admin can create a group' do
    assert_permit GroupPolicy, users(:admin), Group.new, :create
  end

  test 'admin cannot delete the default group' do
    refute_permit GroupPolicy, users(:admin), groups(:default), :destroy
  end

  test 'admin cannot update status of (disable) the default group' do
    refute_permit GroupPolicy, users(:admin), groups(:default), :update_status
  end

  test 'admin can delete any other group' do
    %i[fish fruit veg].each do |group|
      assert_permit GroupPolicy, users(:admin), groups(group), :destroy
    end
  end

  test 'manager cannot delete any group' do
    %i[default fish fruit veg].each do |group|
      refute_permit GroupPolicy, users(:manager), groups(group), :destroy
    end
  end

  test 'member cannot delete any group' do
    %i[default fish fruit veg].each do |group|
      refute_permit GroupPolicy, users(:minion), groups(group), :destroy
    end
  end

  test 'admin can update any group' do
    %i[default fish fruit veg].each do |group|
      assert_permit GroupPolicy, users(:admin), groups(group), :update
    end
  end

  test 'admin can update status of any group' do
    %i[fish fruit veg].each do |group|
      assert_permit GroupPolicy, users(:admin), groups(group), :update_status
    end
  end

  test 'manager can update their own group' do
    %i[default].each do |group|
      assert_permit GroupPolicy, users(:manager), groups(group), :update
    end
  end

  test 'manager can update status of their group' do
    %i[fish].each do |group|
      assert_permit GroupPolicy, users(:fishmonger), groups(group), :update_status
    end
  end

  test 'manager cannot update any other group' do
    %i[fish fruit veg].each do |group|
      refute_permit GroupPolicy, users(:manager), groups(group), :update
    end
  end

  test 'manager cannot update status any other group' do
    %i[fish fruit veg].each do |group|
      refute_permit GroupPolicy, users(:manager), groups(group), :update_status
    end
  end

  test 'member cannot update any group' do
    %i[default fish fruit veg].each do |group|
      refute_permit GroupPolicy, users(:minion), groups(group), :update
    end
  end

  test 'member cannot update status of their group' do
    %i[default fish fruit veg].each do |group|
      refute_permit GroupPolicy, users(:minion), groups(group), :update_status
    end
  end
end
