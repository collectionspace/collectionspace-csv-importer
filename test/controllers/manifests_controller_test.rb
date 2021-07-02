require 'test_helper'

class ManifestsControllerTest < ActionDispatch::IntegrationTest
  test 'an admin can view manifests' do
    sign_in users(:admin)
    assert_can_view(manifests_path)
  end

  # TODO: admin create
  # TODO: admin destroy

  test 'a manager cannot view manifests' do
    sign_in users(:manager)
    refute_can_view(manifests_path)
  end

  test 'a member cannot view manifests' do
    sign_in users(:minion)
    refute_can_view(manifests_path)
  end
end
