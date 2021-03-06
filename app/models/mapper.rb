# frozen_string_literal: true

class Mapper < ApplicationRecord
  self.inheritance_column = :_type_disabled
  has_one_attached :config
  has_many :batches
  before_save :set_title
  validates :profile, :type, :version, presence: true
  validates :url, presence: true, uniqueness: true
  scope :select_options, lambda { |connection|
    where('title LIKE ?', "% (#{connection.profile})").where(enabled: true).order(:title)
  }
  scope :profile_versions, lambda {
    order('profile asc, version asc').pluck(:profile, :version).map { |m| m.join('-') }.uniq
  }

  def download
    config.attach(
      io: StringIO.new(HTTP.get(url).to_s),
      filename: "#{title}.json",
      content_type: 'application/json'
    )
    self.status = true
  end

  def enabled?
    found? && enabled
  end

  def found?
    status
  end

  def profile_version
    "#{profile}-#{version}"
  end

  def self.create_or_update_mapper(json)
    url_found = HTTP.get(json['url']).status.success?
    mapper = Mapper.find_or_create_by!(\
      profile: json['profile'], version: json['version'], type: json['type']
    ) do |m|
      logger.info "Creating mapper for: #{json.inspect}"
      m.url = json['url']
      m.status = url_found
    end
    # commenting out conditional below, as it would prevent updates to mappers from being
    #  picked up if their URLs didn't change
    # if mapper.url != json['url']
      logger.info "Updating mapper for: #{json.inspect}"
      mapper.config.purge if mapper.config.attached?
      mapper.update(
        url: json['url'],
        status: url_found
      )
    # end
    mapper.update(enabled: json['enabled']) if mapper.enabled != json['enabled']
    return mapper if mapper.config.attached? || !url_found

    mapper.download
  end

  def self.refresh
    mappers_url = Rails.configuration.mappers_url
    mappers_response = HTTP.get(mappers_url)
    return false unless mappers_response.status.success?

    begin
      JSON.parse(mappers_response.body.to_s)['mappers'].each do |m|
        create_or_update_mapper(m)
      rescue StandardError => e
        logger.error(e.message)
      end
    rescue JSON::ParserError => e
      logger.error(e.message)
    end
  end

  # gets rid of mappers no longer listed in mapper manifest(s)
  # does not destroy mappers with batches still attached
  # archive step should remove the batch/mapper connection?
  def self.clean_up
    mappers_url = Rails.configuration.mappers_url
    mappers_response = HTTP.get(mappers_url)
    return false unless mappers_response.status.success?

    current_mappers = []

    begin
      JSON.parse(mappers_response.body.to_s)['mappers'].each do |m|
        current_mappers << m['url']
      rescue StandardError => e
        logger.error(e.message)
      end
    rescue JSON::ParserError => e
      logger.error(e.message)
    end

    self.all.each do |m|
      puts "mapper url: #{m.url}"
      puts "batches: #{m.batches_count}"
      return unless m.batches_count == 0

      puts '---'
      is_current = current_mappers.include?(m.url)
      puts is_current ? 'keeping' : 'nuke it!' 
      
      unless is_current
        logger.info "Deleting mapper for #{m.title} as it is no longer included in supported mapper config"
        m.config.purge if m.config.attached?
        self.destroy(m.id)
      end
    end
  end

  private

  def set_title
    self.title = "#{type} (#{profile}-#{version})"
  end
end
