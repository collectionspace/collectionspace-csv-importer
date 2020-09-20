# frozen_string_literal: true

require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  test 'should have the default group' do
    assert Group.default_created?
  end

  test 'can identify the default group' do
    assert groups(:default).default?
    assert_not groups(:fish).default?
  end

  test 'can identify matching groups' do
    g = Group.matching_domain?('veg.edu')
    assert_equal groups(:veg).name, g.first.name
  end

  test 'can identify matching groups with subdomain' do
    g = Group.matching_domain?('sushi.fish.net')
    assert_equal groups(:sushi).name, g.first.name
  end

  test 'will return an empty list for blank domains' do
    assert_equal [], Group.matching_domain?(nil)
  end

  test 'will return an empty list for unidentified domains' do
    assert_equal [], Group.matching_domain?('example.com')
  end

  test 'there can be only 1! (default / supergroup)' do
    group = Group.new(supergroup: true, name: 'Highlander')
    assert_not group.valid?
  end

  test 'cannot duplicate group names' do
    group = Group.new(name: 'Fish')
    assert_not group.valid?
  end

  test 'cannot duplicate group domains' do
    group = Group.new(name: 'Veggies', domain: 'veg.edu')
    assert_not group.valid?
  end

  test 'can identify a disabled group' do
    assert groups(:veg).disabled?
    assert_not groups(:veg).enabled?
  end

  test 'scope group options does include a disabled group' do
    %i[veg].each do |group|
      assert_includes Group.select_options(users(:admin)), Group.find_by(name: groups(group).name)
    end
  end

  test 'scope group options with default includes assigned groups for user' do
    %i[fish fruit sushi xyz].each do |group|
      assert_includes Group.select_options(users(:admin)), Group.find_by(name: groups(group).name)
    end

    assert_equal 2, Group.select_options(users(:manager)).count
    %i[default xyz].each do |group|
      assert_includes Group.select_options(users(:manager)), Group.find_by(name: groups(group).name)
    end

    assert_equal 1, Group.select_options(users(:fishmonger)).count
    %i[fish].each do |group|
      assert_includes Group.select_options(users(:fishmonger)), Group.find_by(name: groups(group).name)
    end
  end

  test 'scope group options without default includes assigned groups for user' do
    assert_equal 1, Group.select_options_without_default(users(:manager)).count
    %i[xyz].each do |group|
      assert_includes Group.select_options_without_default(users(:manager)), Group.find_by(name: groups(group).name)
    end
  end

  # TODO: updating group profile updates connection profile
end
