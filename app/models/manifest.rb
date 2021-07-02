# frozen_string_literal: true

class Manifest < ApplicationRecord
  URL_REGEXP = %r{^(http|https)://[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?$}ix.freeze
  has_many :mappers, dependent: :destroy
  validates :name, presence: true, uniqueness: true
  validates :url, presence: true, uniqueness: true,
                  format: { with: URL_REGEXP, multiline: true, message: 'Invalid' }

  # TODO: jobify
  # gets rid of mappers no longer listed in mapper manifest(s)
  # does not destroy mappers with batches still attached
  # archive step should remove the batch/mapper connection?
  def clean_up
    response = HTTP.get(url)
    return false unless response.status.success?

    current_mappers = []

    begin
      JSON.parse(response.body.to_s)['mappers'].each do |m|
        current_mappers << m['url']
      rescue StandardError => e
        logger.error(e.message)
      end
    rescue JSON::ParserError => e
      logger.error(e.message)
    end

    mappers.each do |m|
      puts "Mapper url: #{m.url}, batches: #{m.batches_count}"
      next unless m.batches_count.zero?
      next if current_mappers.include?(m.url)

      logger.info "Deleting mapper for #{m.title} as it is no longer included in supported mapper config"
      m.config.purge if m.config.attached?
      m.destroy
    end
  end

  # TODO: jobify
  def refresh
    response = HTTP.get(url)
    return false unless response.status.success?

    begin
      JSON.parse(response.body.to_s)['mappers'].each do |m|
        Mapper.create_or_update_from_json(self, m)
      rescue StandardError => e
        logger.error(e.message)
      end
    rescue JSON::ParserError => e
      logger.error(e.message)
    end
  end
end
