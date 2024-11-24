# frozen_string_literal: true

require 'test_helper'

class MissingTermServiceTest < ActiveSupport::TestCase
  Refname = Struct.new(:display_name, :type, :subtype, :identifier)

  setup do
    @batch = batches(:superuser_batch)
    @missingtermservice = MissingTermService.new(batch: @batch, save_to_file: true)

    @refname1 = CollectionSpace::Mapper::Tools::RefName.from_urn(
      "urn:cspace:domain:workauthorities:name(work):item:name(sid1)'Test coll term'"
    )
    @refname2 = CollectionSpace::Mapper::Tools::RefName.from_urn(
      "urn:cspace:domain:vocabularies:name(languages):item:name(sid2)'Esperanto'"
    )
    @refname3 = CollectionSpace::Mapper::Tools::RefName.from_urn(
      "urn:cspace:domain:vocabularies:name(languages):item:name(sid3)'English'"
    )

    @term1 = CollectionSpace::Mapper::UsedTerm.new(
      term: 'Test coll term',
      category: :authority,
      field: 'namedcollection',
      found: false,
      refname: @refname1
    )

    @term1newfield = CollectionSpace::Mapper::UsedTerm.new(
      term: 'Test coll term',
      category: :authority,
      field: 'another coll field',
      found: false,
      refname: @refname1
    )

    @term2 = CollectionSpace::Mapper::UsedTerm.new(
      term: 'Esperanto',
      category: :vocabulary,
      field: 'title language',
      found: false,
      refname: @refname2
    )

    @term3 = CollectionSpace::Mapper::UsedTerm.new(
      term: 'English',
      category: :vocabulary,
      field: 'title language',
      found: true,
      refname: @refname3
    )

    @missingtermservice.add(@term1, 23, '23.1')
    @missingtermservice.add(@term1newfield, 23, '23.1')
    @missingtermservice.add(@term2, 23, '23.1')
    @missingtermservice.add(@term3, 23, '23.1')
  end

  teardown do
    %w[missing_term_occurrence_file uniq_missing_terms_file].map do |ivar|
      @missingtermservice.instance_values[ivar].to_s
    end.each { |path| File.delete(path) if File.exist?(path) }
  end

  test 'can create file of missing term occurrences' do
    filepath = @missingtermservice.instance_values['missing_term_occurrence_file'].to_s
    assert_match(%r{tmp/#{@batch.name}-\d{8}-\d{4}-missing_term_occurrences\.csv},
                 filepath)
    assert(File.exist?(filepath))
    csv_content = <<~CSV
      row_number,row_occ,input_column,category,type,subtype,value
      23,23.1,namedcollection,authority,workauthorities,work,Test coll term
      23,23.1,another coll field,authority,workauthorities,work,Test coll term
      23,23.1,title language,vocabulary,vocabularies,languages,Esperanto
    CSV
    assert_match(csv_content, File.read(filepath))
  end

  test 'can create file of unique missing terms' do
    @missingtermservice.report_uniq_missing_terms
    filepath = @missingtermservice.instance_values['uniq_missing_terms_file'].to_s
    assert_match(%r{tmp/#{@batch.name}-\d{8}-\d{4}-uniq_missing_terms\.csv}, filepath)
    assert(File.exist?(filepath))
    csv_content = <<~CSV
      type,subtype,value
      workauthorities,work,Test coll term
      vocabularies,languages,Esperanto
    CSV
    assert_match(csv_content, File.read(filepath))
  end

  test 'can provide total number of terms used' do
    assert_equal(3, @missingtermservice.total_term_occurrences)
  end

  test 'can select missing terms from full term list' do
    result = @missingtermservice.get_missing([@term1, @term1newfield, @term2, @term3])
    assert_equal(3, result.length)
  end

  test 'can return list of unique missing terms' do
    assert_equal(2, @missingtermservice.report_uniq_missing_terms.length)
  end
end
