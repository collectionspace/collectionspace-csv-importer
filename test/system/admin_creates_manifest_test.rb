# frozen_string_literal: true

require 'application_system_test_case'

class AdminCreatesManifestTest < ApplicationSystemTestCase
  setup do
    sign_in users(:admin)
  end

  test 'admin creates a manifest' do
    visit root_path
    click_on I18n.t('manifest.title.index')
    refute_text 'Hello'
    assert_selector 'h1', text: I18n.t('manifest.title.index')
    fill_in I18n.t('manifest.name'), with: 'Hello'
    fill_in I18n.t('manifest.url'), with: 'https://world.com'
    click_on I18n.t('action.create')
    assert_text 'Hello'
  end
end
