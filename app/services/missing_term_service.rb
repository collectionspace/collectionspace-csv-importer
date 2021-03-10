# frozen_string_literal: true

class MissingTermService
  attr_reader :missing_term_occurrence_file, :uniq_missing_terms_file
  FILE_TYPE = 'csv'
  MISSING_TERM_OCCURRENCE_HEADERS = %i[row_number row_occ input_column category type subtype identifier value].freeze
  UNIQ_MISSING_TERMS_HEADERS = %i[type subtype identifier value].freeze
  
  # mts = MissingTermService.new(batch: 38, save_to_file: true)
  # CSV.foreach(mts.file, headers: true) { |row| puts row }
  def initialize(batch:, save_to_file: false)
    @save_to_file = save_to_file
    @all = {}
    time = Time.now
    filename_stub = "#{batch.name.parameterize}-#{time.strftime('%F').delete('-')}-#{time.strftime('%R').delete(':')}-"
    missing_term_occurrence_filename = "#{filename_stub}missing_term_occurrences.#{FILE_TYPE}"
    @missing_term_occurrence_file = Rails.root.join('tmp', missing_term_occurrence_filename)
    @missing_term_occurrence_headers = MISSING_TERM_OCCURRENCE_HEADERS
    append_headers(@missing_term_occurrence_file, @missing_term_occurrence_headers) if @save_to_file
    
    uniq_missing_terms_filename = "#{filename_stub}uniq_missing_terms.#{FILE_TYPE}"
    @uniq_missing_terms_file = Rails.root.join('tmp', uniq_missing_terms_filename)
    @uniq_missing_terms_headers = UNIQ_MISSING_TERMS_HEADERS
    append_headers(@uniq_missing_terms_file, @uniq_missing_terms_headers) if @save_to_file
  end

  def add(term, row_number, row_occ)
    puts "Processing #{row_number}: #{term[:refname].display_name}"
    type = term[:refname].type
    subtype = term[:refname].subtype
    id = term[:refname].identifier
    @all[type] = {} unless @all.key?(type)
    @all[type][subtype] = {} unless @all[type].key?(subtype)
    @all[type][subtype][id] = [] unless @all[type][subtype].key?(id)
    @all[type][subtype][id] << term
    append(term, row_number, row_occ) if @save_to_file
  end

  def report_uniq_missing_terms
    umt = compile_uniq_missing_terms
    write_uniq_missing_terms(umt) unless umt.empty?
  end

  def message(term)
    "#{term[:field]}: #{term[:refname].display_name} (#{term[:refname].type}/#{term[:refname].subtype})"
  end

  def get_missing(terms)
    terms.select{ |termhash| termhash[:found] == false }
  end

  def total_terms
    compile_uniq_missing_terms if @total_term_count.nil?
    @uniq_term_count
  end

  def total_term_occurrences
    @term_occ_count = 0
    @all.each do |type, subtypehash|
      subtypehash.each do |subtype, idhash|
        idhash.each do |id, idterms|
          @term_occ_count += idterms.length
        end
      end
    end
    @term_occ_count
  end
  
  private

  def compile_uniq_missing_terms
    terms = []
    @all.each do |type, subtypehash|
      subtypehash.each do |subtype, idhash|
        idhash.each do |id, idterms|
          terms << [type, subtype, id, idterms.first[:refname].display_name]
        end
      end
    end
    @uniq_term_count = terms.length
    terms
  end

  def write_uniq_missing_terms(terms)
    return unless @save_to_file

    CSV.open(@uniq_missing_terms_file, 'a') do |csv|
      terms.each{ |term| csv << term }
    end
  end
  
  def append_headers(file, headers)
    return unless @save_to_file

    CSV.open(file, 'a'){ |csv| csv << headers }
  end
  
  def append(term, row_number, row_occ)
    return unless @save_to_file
    puts "Writing #{row_number}: #{term[:refname].display_name} to CSV"
    vals = [row_number,
            row_occ,
            term[:field],
            term[:category],
            term[:refname].type,
            term[:refname].subtype,
            term[:refname].identifier,
            term[:refname].display_name
           ]
    CSV.open(@missing_term_occurrence_file, 'a'){ |csv| csv << vals }
  end

  def total(where)
    @all[where].inject(0) { |t, h| t + h[1].size }
  end
end
