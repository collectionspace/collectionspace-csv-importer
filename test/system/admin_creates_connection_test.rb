# frozen_string_literal: true

require 'application_system_test_case'

class AdminCreatesConnectionTest < ApplicationSystemTestCase
  setup do
    sign_in users(:admin)
  end

  test 'admin creates a valid connection' do
    visit root_path
    click_on users(:admin).email
    assert_selector 'h1', text: I18n.t('user.title.profile')
    find('.create').click
    assert_selector 'h1', text: I18n.t('connection.title.create')
    fill_in I18n.t('connection.placeholder.name'), with: 'anthro.dev'
    fill_in I18n.t('connection.placeholder.url'), with: 'https://anthro.dev.collectionspace.org'
    fill_in I18n.t('connection.placeholder.username'), with: 'admin@anthro.dev.collectionspace.org'
    fill_in I18n.t('connection.placeholder.password'), with: 'Administrator'
    fill_in I18n.t('connection.placeholder.profile_version'), with: 'anthro-4-0-0'
    click_on I18n.t('action.submit')
    assert_text I18n.t('user.title.profile')
    assert_text 'anthro.dev'
  end

  # test 'admin creates a connection with invalid data' do
  #   # TODO
  # end
end
