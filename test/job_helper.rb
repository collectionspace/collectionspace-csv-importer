# frozen_string_literal: true

module JobHelper
  def attach_spreadsheet(step, spreadsheet)
    step.batch.spreadsheet.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', spreadsheet)),
      filename: spreadsheet,
      content_type: 'text/csv',
      identify: false
    )
  end

  def attach_mapper(step, mapper)
    step.batch.mapper.config.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', mapper)),
      filename: mapper,
      content_type: 'application/json',
      identify: false
    )
  end
end
