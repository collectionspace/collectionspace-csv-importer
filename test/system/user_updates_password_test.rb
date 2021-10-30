# frozen_string_literal: true

require 'application_system_test_case'

class UserUpdatesPassword < ApplicationSystemTestCase
  setup do
    sign_in users(:apple)

    visit root_path
    click_on users(:apple).email
    assert_selector 'h1', text: I18n.t('user.title.profile')
  end

  test 'user can update password' do
    fill_in 'user_password', with: 'password'
    fill_in 'user_password_confirmation', with: 'password'
    click_on I18n.t('action.submit')
    assert_text I18n.t('action.updated', record: 'User')
  end

  test 'user cannot update password without password' do
    fill_in 'user_password_confirmation', with: 'password'
    click_on I18n.t('action.submit')
    assert_text "Password can't be blank"
  end

  test 'user cannot update password without confirmation' do
    fill_in 'user_password', with: 'password'
    click_on I18n.t('action.submit')
    assert_text "Password can't be blank"
  end
end
