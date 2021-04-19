# frozen_string_literal: true

class UsersControllerTest < ActionDispatch::IntegrationTest
  # DISABLED USER
  test 'a disabled user can sign in' do
    sign_in users(:disabled)
    get root_path
    assert_response :success
    assert_select 'article.message', /Your email address is not/
  end

  test 'a disabled user cannot update self' do
    sign_in users(:disabled)
    get edit_user_path users(:disabled)
    assert_response :success
    assert_select 'article.message', /Your email address is not/
  end
end
