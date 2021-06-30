# frozen_string_literal: true

module JobHelper
  def attach_spreadsheet(process, spreadsheet)
    process.batch.spreadsheet.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', spreadsheet)),
      filename: spreadsheet,
      content_type: 'text/csv'
    )
  end

  def attach_mapper(process, mapper)
    process.batch.mapper.config.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', mapper)),
      filename: mapper,
      content_type: 'application/json'
    )
  end
end
