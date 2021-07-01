# frozen_string_literal: true

require 'test_helper'

class MapperTest < ActiveSupport::TestCase
  setup do
    @profile_version = 'core-6-0-0'
    @connection = Minitest::Mock.new
    @connection.expect :profile, @profile_version
  end

  test 'scope can match options with profile and version' do
    assert_includes Mapper.select_options(@connection), mappers(:core_collectionobject_6_0)
  end

  test 'scope can skip options with profile and version' do
    assert_not_includes Mapper.select_options(@connection), mappers(:anthro_collectionobject_4_0)
  end

  test 'scope can skip options with not found status' do
    assert_not_includes Mapper.select_options(@connection), mappers(:core_collectionobject_not_found)
  end

  test 'scope can skip options with disabled status' do
    assert_not_includes Mapper.select_options(@connection), mappers(:core_collectionobject_disabled)
  end

  test 'scope can find mappers by manifest name' do
    assert_includes Mapper.by_manifest(manifests(:dev).name), mappers(:core_collectionobject_6_0)
    assert_includes Mapper.by_manifest(manifests(:example).name), mappers(:example)
  end

  test 'scope does not find mappers belonging to another manifest' do
    refute_includes Mapper.by_manifest(manifests(:dev).name), mappers(:example)
    refute_includes Mapper.by_manifest(manifests(:example).name), mappers(:core_collectionobject_6_0)
  end

  test 'scope does not find mappers by manifest that does not exist' do
    refute_includes Mapper.all, Mapper.by_manifest('xyz').first
  end

  test 'reports found status correctly' do
    refute(mappers(:anthro_collectionobject_4_0).found?)
    assert(mappers(:core_collectionobject_6_0).found?)
  end

  # TODO: test mapper create (via refresh)
end
