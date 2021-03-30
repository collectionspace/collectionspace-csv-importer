# frozen_string_literal: true

require 'test_helper'

class MissingTermServiceTest < ActiveSupport::TestCase
  # todo - add tests that ensure CSV data is as expected
  Refname = Struct.new(:display_name, :type, :subtype, :identifier)

  setup do
    @batch = batches(:superuser_batch)
    @missingtermservice = MissingTermService.new(batch: @batch, save_to_file: false)

    @refname1 = Refname.new('Test coll term', 'workauthorities', 'work', 1)
    @refname2 = Refname.new('Esperanto', 'vocabularies', 'languages', 2)
    @refname3 = Refname.new('English', 'vocabularies', 'languages', 3)
    
    @term1 = {
      category: :authority,
      field: 'namedcollection',
      found: false,
      refname: @refname1
    }
    @term1newfield = {
      category: :authority,
      field: 'another coll field',
      found: false,
      refname: @refname1
    }
    @term2 = {
      category: :vocabulary,
      field: 'title language',
      found: false,
      refname: @refname2
    }
    @term3 = {
      category: :vocabulary,
      field: 'title language',
      found: true,
      refname: @refname3
    }
  end

  test 'can create file of missing term occurrences' do
    filepath = @missingtermservice.instance_values['missing_term_occurrence_file'].to_s
    assert_match(/tmp\/#{@batch.name}-\d{8}-\d{4}-missing_term_occurrences\.csv/, filepath)
  end

  test 'can create file of unique missing terms' do
    filepath = @missingtermservice.instance_values['uniq_missing_terms_file'].to_s
    assert_match(/tmp\/#{@batch.name}-\d{8}-\d{4}-uniq_missing_terms\.csv/, filepath)
  end

  test 'can output message to CSV for a term' do
    expect = 'namedcollection: Test coll term (workauthorities/work)'
    assert_equal(expect, @missingtermservice.message(@term1))
  end

  test 'can provide total number of terms used' do
    @missingtermservice.add(@term1, 23, '23.1')
    @missingtermservice.add(@term1newfield, 23, '23.1')
    @missingtermservice.add(@term2, 23, '23.1')
    @missingtermservice.add(@term3, 23, '23.1')
    assert_equal(3, @missingtermservice.total_term_occurrences)
  end

  test 'can select missing terms from full term list' do
    result = @missingtermservice.get_missing([@term1, @term1newfield, @term2, @term3])
    assert_equal(3, result.length)
  end

  test 'can return list of unique missing terms' do
    @missingtermservice.add(@term1, 23, '23.1')
    @missingtermservice.add(@term1newfield, 23, '23.1')
    @missingtermservice.add(@term2, 23, '23.1')
    assert_equal(2, @missingtermservice.report_uniq_missing_terms.length)
  end
end
