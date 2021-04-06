# frozen_string_literal: true

require 'test_helper'

class ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:superuser)
    @connection = connections(:core_superuser)
    @valid_params = {
      name: 'core.dev',
      url: 'https://core.dev.collectionspace.org/cspace-services',
      username: 'admin@core.collectionspace.org',
      password: 'Administrator',
      profile: 'core-6-0-0',
      user_id: users(:superuser).id
    }
  end

  test 'should get new when given the signed in users id' do
    get new_connection_url(user_id: users(:superuser).id)
    assert_response :success
  end

  test 'should create connection' do
    assert_difference('Connection.count') do
      post connections_url, params: { connection: @valid_params }
    end

    assert_redirected_to edit_user_url(users(:superuser))
  end

  test 'should redirect show connection' do
    get connection_url(@connection)
    assert_response :redirect
  end

  test 'should get edit' do
    get edit_connection_url(@connection)
    assert_response :success
  end

  test 'should update connection' do
    patch connection_url(@connection), params: { connection: @valid_params }
    assert_redirected_to edit_connection_url(@connection)
  end

  test 'cannot create a connection with an invalid profile' do
    invalid_params = @valid_params.dup
    invalid_params[:profile] = 'nope'
    run_update(
      connection_url(@connection),
      @connection,
      { connection: invalid_params }
    )
    assert_equal 'core-6-0-0', @connection.profile
  end

  test 'should destroy connection' do
    assert_difference('Connection.count', -1) do
      delete connection_url(@connection)
    end

    assert_redirected_to edit_user_path(users(:superuser))
  end
end
