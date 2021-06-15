# frozen_string_literal: true

require 'application_system_test_case'

class UsersAdminTest < ApplicationSystemTestCase
  setup do
    sign_in users(:admin)
  end

  test 'browse users as an admin' do
    visit users_url
    assert_selector 'h1', text: 'Users'
    assert_selector 'tbody tr', count: Pagy::VARS[:items]

    # we should see but not link to the superuser
    assert_text users(:superuser).email
    assert_selector 'a', text: users(:superuser).email, count: 0

    # we should link to any other type of user
    assert_selector 'a', text: users(:admin).email
    assert_selector 'a', text: users(:fishmonger).email

    # can paginate users
    click_on '2'
    assert_selector 'a', text: users(:apple).email
  end

  test 'can view a user with connections' do
    visit users_url
    # wouldn't allow this elsewhere but this is a small and controlled dataset
    click_on '2'
    click_on users(:salmon).email
    assert_text connections(:sushi_salmon).name
  end
end
