# frozen_string_literal: true

require 'test_helper'

class BatchTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess
  setup do
    @params = {
      name: 'batch1',
      user_id: users(:superuser).id,
      group_id: users(:superuser).group.id,
      connection_id: connections(:core_superuser).id,
      mapper_id: mappers(:core_collectionobject_6_0).id,
      spreadsheet: fixture_file_upload('files/core-cataloging.csv', 'text/csv'),
      batch_config: '{ "delimiter": ";", "default_values": { "collection": "library-collection" } }'
    }
    @invalid_params = @params.dup
  end

  test 'cannot create batch without a name' do
    @params.delete(:name)
    refute Batch.new(@params).valid?
  end

  test 'cannot create batch without a user' do
    @params.delete(:user_id)
    refute Batch.new(@params).valid?
  end

  test 'cannot create batch without a group' do
    @params.delete(:group_id)
    refute Batch.new(@params).valid?
  end

  test 'cannot create batch without a connection' do
    @params.delete(:connection_id)
    Batch.new(@params).valid?
  end

  test 'cannot create batch without a mapper' do
    @params.delete(:mapper_id)
    refute Batch.new(@params).valid?
  end

  test 'can create a batch with valid params' do
    assert Batch.new(@params).valid?
  end

  test 'cannot create a batch with an invalid mapper' do
    @invalid_params[:mapper_id] = mappers(:anthro_collectionobject_4_1).id
    assert_not Batch.new(@invalid_params).valid?
  end

  test 'cannot create a batch with invalid json' do
    @invalid_params[:batch_config] = '{123}'
    assert_not Batch.new(@invalid_params).valid?
  end

  test 'json batch_config is received by handler' do
    batch = Batch.new(@params)
    value = batch.handler.mapper.batchconfig.default_values['collection']
    assert 'library-collection', value
  end

  test 'can indicate when possible to cancel' do
    batch = Batch.new(@params)
    batch.save
    batch.start! # pending
    assert batch.can_cancel?
    batch.run! # running
    assert batch.can_cancel?
  end

  test 'can indicate when possible to reset' do
    batch = Batch.new(@params)
    batch.save
    batch.start! # pending
    refute batch.can_reset?
    batch.cancel! # cancelled
    assert batch.can_reset?
    batch.retry! # ready
    batch.start! # pending again
    refute batch.can_reset?
    batch.run! # running
    batch.failed! # oops, something went wrong
    assert batch.can_reset?
  end

  test 'can get the active step' do
    assert_equal :preprocessing, batches(:superuser_batch_preprocessing).step.name
    assert_equal :processing, batches(:superuser_batch_processing).step.name
    assert_equal :transferring, batches(:superuser_batch_transferring).step.name
    assert_equal :archiving, batches(:superuser_batch_archiving).step.name
  end

  test 'can identify an expired batch' do
    refute batches(:superuser_batch_preprocessing).expired?
    refute batches(:superuser_batch_processing).expired?
    refute batches(:superuser_batch_transferring).expired?
    refute batches(:superuser_batch_archiving).expired?

    assert batches(:superuser_batch_expired).expired?
    assert batches(:superuser_batch_archived).expired?

    expired = 0
    Batch.expired { |_b| expired += 1 }
    assert 2, expired
  end
end
