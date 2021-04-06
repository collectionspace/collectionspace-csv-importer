require 'test_helper'

class MapperTest < ActiveSupport::TestCase
  setup do
    @profile_version = 'core-6.0.0'
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

  test 'reports found status correctly' do
    refute(mappers(:anthro_collectionobject_4_0).found?)
    assert(mappers(:core_collectionobject_6_0).found?)
  end

  # TODO: test mapper create (via refresh)
end
