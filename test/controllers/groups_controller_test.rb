# frozen_string_literal: true

require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest
  test 'an admin can view groups' do
    sign_in users(:admin)
    assert_can_view(groups_path)
  end

  test 'a manager cannot view groups' do
    sign_in users(:manager)
    refute_can_view(groups_path)
  end

  test 'a member cannot view groups' do
    sign_in users(:minion)
    refute_can_view(groups_path)
  end

  # CREATE
  test 'an admin can create a group' do
    sign_in users(:admin)
    assert_can_create(
      groups_url, 'Group', { group: { name: 'Birds' } }, groups_path
    )
  end

  test 'an admin cannot create a group with invalid attributes' do
    sign_in users(:admin)
    refute_can_create(
      groups_url, 'Group', { group: { name: nil } }
    )
  end

  test 'a manager cannot create a group' do
    sign_in users(:manager)
    refute_can_create(
      groups_url, 'Group', { group: { name: 'Birds' } }
    )
  end

  test 'a member cannot create a group' do
    sign_in users(:minion)
    refute_can_create(
      groups_url, 'Group', { group: { name: 'Birds' } }
    )
  end

  # UPDATE
  test 'an admin can update a group' do
    sign_in users(:admin)
    group = groups(:fish)
    run_update(
      group_url(group),
      group,
      { group: { name: 'Fish updated!', profile: 'anthro-4-0-0' } },
      edit_group_path(group)
    )
    assert_equal 'Fish updated!', group.name
    assert_equal 'anthro-4-0-0', group.profile
  end

  test 'an admin cannot update a group with invalid attributes' do
    sign_in users(:admin)
    group = groups(:fish)
    run_update(
      group_url(group),
      group,
      { group: { name: nil } },
    )
    refute_nil group.name
  end

  test 'an admin cannot set the profile for the default group' do
    sign_in users(:admin)
    group = groups(:default)
    run_update(
      group_url(group),
      group,
      { group: { profile: 'core' } },
      edit_group_path(group)
    )
    assert_nil group.profile
  end

  test 'an admin cannot duplicate a domain for a group' do
    sign_in users(:admin)
    group = groups(:fish)
    run_update(
      group_url(group),
      group,
      { group: { domain: 'veg.edu' } }
    )
    assert_not_equal 'veg.edu', group.domain
  end

  # DELETE
  test 'an admin can delete a group' do
    sign_in users(:admin)
    group = groups(:fish)
    assert_difference('Group.count', -1) do
      delete group_url(group)
    end
    assert_redirected_to groups_url
  end
end
