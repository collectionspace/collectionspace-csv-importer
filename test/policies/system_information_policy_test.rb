# frozen_string_literal: true

require 'test_helper'

class SystemInformationPolicyTest < ActiveSupport::TestCase
  test 'admin can access system information' do
    assert_permit SystemInformationPolicy, users(:admin), nil, :sysinfo
  end

  test 'manager cannot access system information' do
    refute_permit SystemInformationPolicy, users(:manager), nil, :sysinfo
  end

  test 'member cannot access system information' do
    refute_permit SystemInformationPolicy, users(:minion), nil, :sysinfo
  end
end
