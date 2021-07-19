# frozen_string_literal: true

require 'test_helper'

class RecordCacheServiceTest < ActiveSupport::TestCase
  setup do
    @cache_svc = RecordCacheService.new(batch_id: 23)
    
    @result = Minitest::Mock.new
    @result.expect :record_status, :existing
    @result.expect :record_status, :existing
    @result.expect :xml, 'xmlvalue'
    @result.expect :identifier, 'idvalue'
    @result.expect :csid, 'csidvalue'
    @result.expect :uri, 'urivalue'
    @result.expect :refname, 'refnamevalue'

    @occ_num = '66.1'
    @cache_svc.cache_processed(@occ_num, @result)
    @cached = Rails.cache.read('23.66.1', namespace: 'processed')
    @retrieved = @cache_svc.retrieve_cached(@occ_num)


    @result_w_blob = Minitest::Mock.new
    @result_w_blob.expect :record_status, :existing
    @result_w_blob.expect :record_status, :existing
    @result_w_blob.expect :xml, 'xmlvalue'
    @result_w_blob.expect :identifier, 'idvalue'
    @result_w_blob.expect :csid, 'csidvalue'
    @result_w_blob.expect :uri, 'urivalue'
    @result_w_blob.expect :refname, 'refnamevalue'

    @occ_num_w_blob = '67.1'
    @blob_uri = 'http://blob.uri.com'
    @cache_svc.cache_processed(@occ_num_w_blob, @result_w_blob, @blob_uri)
    @cached_w_blob = Rails.cache.read('23.67.1', namespace: 'processed')
    @retrieved_w_blob = @cache_svc.retrieve_cached(@occ_num_w_blob)
  end

  test 'can cache a hash of processed data' do
    assert_instance_of(Hash, @cached)
  end

  test 'can cache extra key/value pairs for existing records' do
    assert_equal('csidvalue', @cached['csid'])
  end

  test 'can cache extra blobURI key/value pair for media records' do
    assert_equal(@blob_uri, @cached_w_blob['bloburi'])
  end

  test 'can retrieve cached data' do
    assert_instance_of(Hash, @retrieved)
    assert_equal('xmlvalue', @retrieved['xml'])
    assert_instance_of(Hash, @retrieved_w_blob)
    assert_equal(@blob_uri, @retrieved_w_blob['bloburi'])
  end
end
