# frozen_string_literal: true

require 'test_helper'

class ConnectionTest < ActiveSupport::TestCase
  setup do
    @params = {
      name: 'core.dev',
      url: 'https://core.dev.collectionspace.org/cspace-services',
      username: 'admin@core.collectionspace.org',
      password: 'Administrator',
      profile: 'core-6-0-0',
      user_id: users(:superuser).id,
      group_id: users(:superuser).group_id
    }
  end

  test 'cannot create connection without a name' do
    @params.delete(:name)
    refute Connection.new(@params).valid?
  end

  test 'cannot create connection without a url' do
    @params.delete(:url)
    refute Connection.new(@params).valid?
  end

  test 'cannot create connection without a username' do
    @params.delete(:username)
    refute Connection.new(@params).valid?
  end

  test 'cannot create connection without a password' do
    @params.delete(:password)
    refute Connection.new(@params).valid?
  end

  test 'can create a connection' do
    c = Connection.new(@params)
    c.save
    assert_equal 'core.dev', c.name
  end

  test 'disabling connection unsets primary (default)' do
    c1 = connections(:core_superuser)
    assert(c1.primary?)
    c1.update(enabled: false)
    assert_not(c1.primary?)
  end

  test 'sets primary (default) exclusively' do
    c1 = connections(:core_superuser)
    c2 = connections(:fcart_superuser)
    assert(c1.primary?)
    assert_not(c2.primary?)
    c2.update(primary: true)
    c1.reload
    assert_not(c1.primary?)
    assert(c2.primary?)
  end

  test 'can return RefCache and CSIDCache on two different Redis DBs' do
    conn = connections(:core_superuser)
    refcache = conn.refcache
    assert(refcache.is_a?(CollectionSpace::RefCache))
    csidcache = conn.csidcache
    assert(csidcache.is_a?(CollectionSpace::RefCache))
    assert(csidcache.config[:redis] != refcache.config[:redis])
  end
end
