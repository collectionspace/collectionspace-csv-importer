# frozen_string_literal: true

require 'application_system_test_case'

class UsersManagerTest < ApplicationSystemTestCase
  setup do
    sign_in users(:fruit_n_veg_man)
  end

  test 'browse users as manager should be scoped to group (fish) with links' do
    visit users_url
    assert_selector 'h1', text: 'Users'
    assert_selector 'tbody tr', count: users.select { |u|
      u.group.name == users(:fishmonger).group.name
    }.count
    # we should link to users in the same group
    assert_selector 'a', text: users(:fishmonger).email
    assert_selector 'a', text: users(:tuna).email

    # we should not see these
    refute_text users(:admin).email
    refute_text users(:apple).email
    refute_text users(:brocolli).email
  end

  # TODO
  # - create a connection & confirm available
  # - go to create a batch and confirm ok
  # - change groups
  # - confirm there are no connections
  # - confirm cannot create batch
end
