# frozen_string_literal: true

require 'test_helper'

class RecordUniquenessServiceTest < ActiveSupport::TestCase
  # todo - future tests to verify CSV is written to as expected?
  setup do
    # generic object as log_report since I'm not sure how to test additions to a CSV
    @service = RecordUniquenessService.new(log_report: Object.new)
  end

  test 'can report properly on all unique ids' do
    @service.add(row: 2, row_occ: '2.1', rec_id: '2')
    @service.add(row: 3, row_occ: '3.1', rec_id: '3')
    @service.add(row: 4, row_occ: '4.1', rec_id: '4')
    @service.add(row: 5, row_occ: '5.1', rec_id: '5')
    @service.check_for_non_unique
    refute(@service.any_non_uniq)
    assert_equal(0, @service.non_uniq_ct)
  end

  test 'can report properly on non-unique ids' do
    @service.add(row: 2, row_occ: '2.1', rec_id: '2')
    @service.add(row: 3, row_occ: '3.1', rec_id: '2')
    @service.add(row: 4, row_occ: '4.1', rec_id: '4')
    @service.add(row: 5, row_occ: '5.1', rec_id: '4')
    @service.add(row: 5, row_occ: '5.2', rec_id: '4')
    @service.add(row: 6, row_occ: '6.1', rec_id: '5')
    @service.check_for_non_unique
    assert(@service.any_non_uniq)
    assert_equal(5, @service.non_uniq_ct)
  end
end
