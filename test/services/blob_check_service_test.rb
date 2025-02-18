# frozen_string_literal: true

require 'test_helper'

class RecordCacheServiceTest < ActiveSupport::TestCase
  setup do
    config = CollectionSpace::Configuration.new(
      base_uri: "https://anthro.dev.collectionspace.org/cspace-services",
      username: "admin@anthro.collectionspace.org",
      password: "Administrator"
    )
    @client = CollectionSpace::Client.new(config)
    @svc = BlobCheckService.new(client: @client)
  end

  test 'returns :absent when media has no blob' do
    stub_request(:get, "https://anthro.dev.collectionspace.org/"\
                 "cspace-services/media/2c7f65fa-70df-4597-85c2/blob"\
                 "?pgSz=25&wf_deleted=false").
      with(
        headers: {
	  'Accept'=>'*/*',
	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
	  'Authorization'=>'Basic YWRtaW5AYW50aHJvLmNvbGxlY3Rpb25zcGFjZS5vcmc6QWRtaW5pc3RyYXRvcg==',
	  'User-Agent'=>'Ruby'
        }).
      to_return(
        status: 400,
        body: "get failed on org.collectionspace.services.media.MediaResource csid=null"
      )

    assert_equal(
      :absent,
      @svc.status(uri: "media/2c7f65fa-70df-4597-85c2")
    )
  end

  test 'returns :present when media has blob' do
    stub_request(:get, "https://anthro.dev.collectionspace.org/"\
                 "cspace-services/media/7b49f95b-6c5d-4545-bc7b/blob"\
                 "?pgSz=25&wf_deleted=false").
      with(
        headers: {
	  'Accept'=>'*/*',
	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
	  'Authorization'=>'Basic YWRtaW5AYW50aHJvLmNvbGxlY3Rpb25zcGFjZS5vcmc6QWRtaW5pc3RyYXRvcg==',
	  'User-Agent'=>'Ruby'
        }).
      to_return(
        status: 200
      )

    assert_equal(
      :present,
      @svc.status(uri: "media/7b49f95b-6c5d-4545-bc7b")
    )
  end

  test 'returns :absent when restrictedmedia has no blob' do
    stub_request(:get, "https://anthro.dev.collectionspace.org/"\
                 "cspace-services/restrictedmedia/ce059844-1295-4886-8047/blob"\
                 "?pgSz=25&wf_deleted=false").
      with(
        headers: {
	  'Accept'=>'*/*',
	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
	  'Authorization'=>'Basic YWRtaW5AYW50aHJvLmNvbGxlY3Rpb25zcGFjZS5vcmc6QWRtaW5pc3RyYXRvcg==',
	  'User-Agent'=>'Ruby'
        }).
      to_return(
        status: 400,
        body: "get failed on org.collectionspace.services.restrictedmedia.RestrictedMediaResource csid=null"
      )

    assert_equal(
      :absent,
      @svc.status(uri: "restrictedmedia/ce059844-1295-4886-8047")
    )
  end

  test 'returns :present when restrictedmedia has blob' do
    stub_request(:get, "https://anthro.dev.collectionspace.org/"\
                 "cspace-services/restrictedmedia/7b49f95b-6c5d-4545-bc7b/blob"\
                 "?pgSz=25&wf_deleted=false").
      with(
        headers: {
	  'Accept'=>'*/*',
	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
	  'Authorization'=>'Basic YWRtaW5AYW50aHJvLmNvbGxlY3Rpb25zcGFjZS5vcmc6QWRtaW5pc3RyYXRvcg==',
	  'User-Agent'=>'Ruby'
        }).
      to_return(
        status: 200
      )

    assert_equal(
      :present,
      @svc.status(uri: "restrictedmedia/7b49f95b-6c5d-4545-bc7b")
    )
  end
end
