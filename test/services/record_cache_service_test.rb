# frozen_string_literal: true

require 'test_helper'

class RecordCacheServiceTest < ActiveSupport::TestCase
  setup do
    @result = Minitest::Mock.new
    @result.expect :record_status, :existing
    @result.expect :record_status, :existing
    @result.expect :xml, 'xmlvalue'
    @result.expect :identifier, 'idvalue'
    @result.expect :csid, 'csidvalue'
    @result.expect :uri, 'urivalue'
    @result.expect :refname, 'refnamevalue'

    @cache_svc = RecordCacheService.new(batch_id: 23)
    @occ_num = '66.1'
    @cache_svc.cache_processed(@occ_num, @result)
    @cached = Rails.cache.read('23.66.1', namespace: 'processed')
  end

  test 'can cache a hash of processed data' do
    assert_instance_of(Hash, @cached)
  end

  test 'can cache extra key/value pairs for existing records' do
    assert_equal('csidvalue', @cached['csid'])
  end

  test 'can retrieve cached data' do
    cached = @cache_svc.retrieve_cached(@occ_num)
    assert_instance_of(Hash, cached)
    assert_equal('xmlvalue', cached['xml'])
  end
end
