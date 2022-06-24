# frozen_string_literal: true

require 'test_helper'

class ManifestTest < ActiveSupport::TestCase
  test 'can identify unused manifests' do
    refute manifests(:dev).unused?
    assert manifests(:example).unused?

    Manifest.unused { |m| assert_equal manifests(:example), m }
  end
end
