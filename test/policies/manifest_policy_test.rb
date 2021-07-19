# frozen_string_literal: true

require 'test_helper'

class ManifestPolicyTest < ActiveSupport::TestCase
  test 'admin can access manifests' do
    assert_permit ManifestPolicy, users(:admin), nil, :index
  end

  test 'manager cannot access manifests' do
    refute_permit ManifestPolicy, users(:manager), nil, :index
  end

  test 'member cannot access manifests' do
    refute_permit ManifestPolicy, users(:minion), nil, :index
  end

  test 'admin can create manifests' do
    assert_permit ManifestPolicy, users(:admin), nil, :create
  end

  test 'manager cannot create manifests' do
    refute_permit ManifestPolicy, users(:manager), nil, :index
  end

  test 'member cannot create manifests' do
    refute_permit ManifestPolicy, users(:minion), nil, :index
  end
end
