# frozen_string_literal: true

class ReportService
  FILE_TYPE = 'csv'

  attr_reader :file, :headers

  def initialize(name:, columns:, save_to_file: false)
    @file = Rails.root.join('tmp', "#{name}.#{FILE_TYPE}")
    @headers = columns
    @save_to_file = save_to_file
    append(@headers) if @save_to_file
  end

  def append(message)
    return unless @save_to_file

    addable = if message.respond_to?(:key)
                message.values_at(*headers)
              else
                message.map(&:to_s)
              end
    add_to_report(addable)
  end

  private

  def add_to_report(message)
    CSV.open(file, 'a') do |csv|
      csv << message
    end
  end
end
