# frozen_string_literal: true

require 'test_helper'

class TransferStatusTest < ActiveSupport::TestCase
  setup do
    @bad_status = TransferStatus.new
    @bad_status.bad('so bad')

    @good_status = TransferStatus.new
    @good_status.good('it worked')
  end

  test 'can set bad status' do
    refute(@bad_status.success)
    assert_equal('so bad', @bad_status.message)
    assert_nil(@bad_status.uri)
    assert_nil(@bad_status.action)
  end

  test 'can set good status' do
    assert(@good_status.success)
    assert_equal('it worked', @good_status.message)
    assert_nil(@good_status.uri)
    assert_nil(@good_status.action)
  end

  test 'can set uri' do
    @good_status.set_uri('https://www.link.org')
    assert_equal('https://www.link.org', @good_status.uri)
  end

  test 'can set action' do
    @good_status.set_action('Updated')
    assert_equal('Updated', @good_status.action)
  end

  test 'can return success?' do
    assert(@good_status.success?)
    refute(@bad_status.success?)
  end
end
