# frozen_string_literal: true

require 'test_helper'

class ManifestTest < ActiveSupport::TestCase
  test 'can identify active manifests' do
    assert manifests(:dev).active?
    assert manifests(:protected).active?
  end

  test 'can identify unused manifests' do
    assert manifests(:example).unused?
    Manifest.unused { |m| assert_equal manifests(:example), m }
  end
end
