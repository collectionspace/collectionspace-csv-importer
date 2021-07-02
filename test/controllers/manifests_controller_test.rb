require 'test_helper'

class ManifestsControllerTest < ActionDispatch::IntegrationTest
  test 'an admin can view manifests' do
    sign_in users(:admin)
    assert_can_view(manifests_path)
  end

  test 'an admin can create a manifest with valid params' do
    sign_in users(:admin)
    assert_can_create(
      manifests_url,
      'Manifest',
      { manifest: { name: 'new', url: 'http://new.com' } },
      manifests_path
    )
  end

  test 'an admin cannot create a manifest with a duplicate name' do
    sign_in users(:admin)
    refute_can_create(
      manifests_url,
      'Manifest',
      { manifest: { name: 'example', url: 'http://example.com' } }
    )
  end

  test 'an admin cannot create a manifest without a valid url' do
    sign_in users(:admin)
    refute_can_create(
      manifests_url,
      'Manifest',
      { manifest: { name: 'hello', url: 'world' } }
    )
  end

  test 'an admin can delete a manifest' do
    sign_in users(:admin)
    manifest = manifests(:example)
    assert_difference('Manifest.count', -1) do
      delete manifest_url(manifest)
    end
    assert_redirected_to manifests_url
  end

  test 'an admin cannot delete a manifest that is in use' do
    sign_in users(:admin)
    manifest = manifests(:dev)
    assert_no_difference('Manifest.count') do
      delete manifest_url(manifest)
    end
    assert_redirected_to manifests_url
  end

  test 'a manager cannot view manifests' do
    sign_in users(:manager)
    refute_can_view(manifests_path)
  end

  test 'a member cannot view manifests' do
    sign_in users(:minion)
    refute_can_view(manifests_path)
  end
end
