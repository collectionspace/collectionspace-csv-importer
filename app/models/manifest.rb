# frozen_string_literal: true

class Manifest < ApplicationRecord
  URL_REGEXP = %r{^(http|https)://[a-z0-9]+([\-.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?$}ix.freeze
  has_many :mappers, dependent: :destroy
  validates :name, presence: true, uniqueness: true
  validates :url, presence: true, uniqueness: true,
                  format: { with: URL_REGEXP, multiline: true, message: 'Invalid' }

  def clean_up
    mappers.find_all { |m| m.batches_count.zero? }.each do |mapper|
      mapper.destroy
      yield self if block_given? # stream ui updates
    end
  end

  def unused?
    mappers.find_all { |m| m.batches_count.zero? }.count == mappers_count
  end

  def import
    response = HTTP.get(url)
    return false unless response.status.success?

    begin
      JSON.parse(response.body.to_s)['mappers'].each do |m|
        record = Mapper.create_or_update_from_json(self, m)
        yield record if block_given? # stream ui updates
      rescue StandardError => e
        logger.error(e.message)
      end
    rescue JSON::ParserError => e
      logger.error(e.message)
    end
  end

  def self.unused(&block)
    all.in_batches do |m|
      m.find_all(&:unused?).each(&block)
    end
  end
end
