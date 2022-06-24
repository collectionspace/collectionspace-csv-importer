# frozen_string_literal: true

require 'test_helper'

class BatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
    @valid_params = {
      name: 'batch1',
      group_id: groups(:default).id,
      connection_id: connections(:core_superuser).id,
      mapper_id: mappers(:core_collectionobject_6_0).id,
      spreadsheet: fixture_file_upload('files/core-cataloging.csv', 'text/csv'),
      batch_config: '{ "delimiter": ";", "default_values": { "collection": "library-collection" } }'
    }
    @invalid_params = @valid_params.dup
  end

  test 'a user can view batches' do
    assert_can_view(batches_path)
  end

  test 'a user can access the new batch form' do
    assert_can_view(new_batch_path)
  end

  test 'should create a batch with valid params' do
    assert_difference('Batch.count') do
      post batches_url, params: { batch: @valid_params }
    end

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_equal 'core-cataloging.csv', Batch.last.spreadsheet.filename.to_s
    assert_equal 2, Batch.last.num_rows
  end

  test 'admin can create a batch for another group' do
    params = @valid_params.dup
    params[:group_id] = groups(:fish).id
    assert_difference('Batch.count') do
      post batches_url, params: { batch: params }
    end
    assert_equal groups(:fish), Batch.last.group
  end

  test 'a non-admin user can create a batch but group is set to their group' do
    sign_in users(:manager)
    params = @valid_params.dup
    params[:group_id] = groups(:fish).id
    assert_difference('Batch.count') do
      post batches_url, params: { batch: params }
    end
    assert_equal groups(:default), Batch.last.group
  end

  test 'should not create a batch with no connection' do
    @invalid_params.delete :connection_id
    assert_no_difference('Batch.count') do
      post batches_url, params: { batch: @invalid_params }
    end
  end

  test 'should not create a batch with an invalid mapper' do
    @invalid_params[:mapper_id] = mappers(:anthro_collectionobject_4_1).id
    assert_no_difference('Batch.count') do
      post batches_url, params: { batch: @invalid_params }
    end
  end

  test 'should not create a batch with malformed csv' do
    @invalid_params[:spreadsheet] = fixture_file_upload('files/malformed.csv', 'text.csv')
    assert_no_difference('Batch.count') do
      post batches_url, params: { batch: @invalid_params }
    end
  end

  test 'should not create a batch with greater than max limit csv' do
    @invalid_params[:spreadsheet] = fixture_file_upload('files/too_large.csv', 'text.csv')
    assert_no_difference('Batch.count') do
      post batches_url, params: { batch: @invalid_params }
    end
  end

  test 'should not create a batch with malformed json' do
    @invalid_params[:batch_config] = '{abcdef}'
    assert_no_difference('Batch.count') do
      post batches_url, params: { batch: @invalid_params }
    end
  end

  test 'should destroy batch' do
    batch = batches(:minion_batch)
    assert_difference('Batch.count', -1) do
      delete batch_url(batch)
    end

    assert_redirected_to batches_path
  end
end
