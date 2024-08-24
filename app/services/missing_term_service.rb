# frozen_string_literal: true

class MissingTermService
  attr_reader :missing_term_occurrence_file, :uniq_missing_terms_file

  FILE_TYPE = 'csv'
  MISSING_TERM_OCCURRENCE_HEADERS = %i[row_number row_occ input_column category type
                                       subtype value].freeze
  UNIQ_MISSING_TERMS_HEADERS = %i[type subtype value].freeze

  # mts = MissingTermService.new(batch: 38, save_to_file: true)
  # CSV.foreach(mts.file, headers: true) { |row| puts row }
  def initialize(batch:, save_to_file: false)
    @save_to_file = save_to_file
    @all = []
    time = Time.now
    filename_stub = "#{batch.name.parameterize}-#{time.strftime('%F').delete('-')}-#{time.strftime('%R').delete(':')}-"
    missing_term_occurrence_filename = "#{filename_stub}missing_term_occurrences.#{FILE_TYPE}"
    @missing_term_occurrence_file = Rails.root.join('tmp',
                                                    missing_term_occurrence_filename)
    @missing_term_occurrence_headers = MISSING_TERM_OCCURRENCE_HEADERS
    if @save_to_file
      append_headers(@missing_term_occurrence_file, @missing_term_occurrence_headers)
    end

    uniq_missing_terms_filename = "#{filename_stub}uniq_missing_terms.#{FILE_TYPE}"
    @uniq_missing_terms_file = Rails.root.join('tmp', uniq_missing_terms_filename)
    @uniq_missing_terms_headers = UNIQ_MISSING_TERMS_HEADERS
    if @save_to_file
      append_headers(@uniq_missing_terms_file, @uniq_missing_terms_headers)
    end
  end

  def add(term, row_number, row_occ)
    return if term.found?

    @all << term
    append(term, row_number, row_occ) if @save_to_file
  end

  def report_uniq_missing_terms
    umt = compile_uniq_missing_terms
    write_uniq_missing_terms(umt) unless umt.empty?
    umt
  end

  def get_missing(terms) = terms.select(&:missing?)

  def total_terms
    compile_uniq_missing_terms if @total_term_count.nil?
    @uniq_term_count
  end

  def total_term_occurrences = @all.length

  private

  def compile_uniq_missing_terms
    terms = @all.group_by(&:key)
      .map { |_key, arr| [arr[0].type, arr[0].subtype, arr[0].display_name] }
    @uniq_term_count = terms.length
    terms
  end

  def write_uniq_missing_terms(terms)
    return unless @save_to_file

    CSV.open(@uniq_missing_terms_file, 'a') do |csv|
      terms.each { |term| csv << term }
    end
  end

  def append_headers(file, headers)
    return unless @save_to_file

    CSV.open(file, 'a') { |csv| csv << headers }
  end

  def append(term, row_number, row_occ)
    return unless @save_to_file

    vals = [row_number,
            row_occ,
            term.field,
            term.category,
            term.type,
            term.subtype,
            term.display_name]
    CSV.open(@missing_term_occurrence_file, 'a') { |csv| csv << vals }
  end
end
