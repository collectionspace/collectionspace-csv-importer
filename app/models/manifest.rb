# frozen_string_literal: true

class Manifest < ApplicationRecord
  has_many :mappers
  validates :name, :url, presence: true, uniqueness: true

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
      puts "mapper url: #{m.url}"
      puts "batches: #{m.batches_count}"
      next unless m.batches_count.zero?

      puts '---'
      is_current = current_mappers.include?(m.url)
      puts is_current ? 'keeping' : 'nuke it!'

      next if is_current

      logger.info "Deleting mapper for #{m.title} as it is no longer included in supported mapper config"
      m.config.purge if m.config.attached?
      destroy(m.id)
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
