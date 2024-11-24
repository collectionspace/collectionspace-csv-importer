# frozen_string_literal: true

require 'test_helper'

class RecordUniquenessServiceTest < ActiveSupport::TestCase
  # TODO: - future tests to verify CSV is written to as expected?
  setup do
    # generic object as log_report since I'm not sure how to test additions to a CSV
    @service = RecordUniquenessService.new(log_report: Object.new)
  end

  test 'can report properly on all unique ids' do
    @service.add(row_num: 2, row_occ: '2.1', rec_id: '2')
    @service.add(row_num: 3, row_occ: '3.1', rec_id: '3')
    @service.add(row_num: 4, row_occ: '4.1', rec_id: '4')
    @service.add(row_num: 5, row_occ: '5.1', rec_id: '5')
    refute(@service.any_non_unique?)
    assert_equal(0, @service.non_unique_count)
  end

  test 'can report properly on non-unique ids' do
    @service.add(row_num: 2, row_occ: '2.1', rec_id: '2')
    @service.add(row_num: 3, row_occ: '3.1', rec_id: '2')
    @service.add(row_num: 4, row_occ: '4.1', rec_id: '4')
    @service.add(row_num: 5, row_occ: '5.1', rec_id: '4')
    @service.add(row_num: 5, row_occ: '5.2', rec_id: '4')
    @service.add(row_num: 6, row_occ: '6.1', rec_id: '5')
    assert(@service.any_non_unique?)
    assert_equal(5, @service.non_unique_count)
  end
end
