# frozen_string_literal: true

class Mapper < ApplicationRecord
  self.inheritance_column = :_type_disabled
  has_one_attached :config
  has_many :batches
  belongs_to :manifest
  before_save :set_title
  validates :profile, :type, :version, presence: true
  validates :url, :digest, presence: true, uniqueness: true
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

  def self.create_or_update_from_json(manifest, json)
    url_found = HTTP.get(json['url']).status.success?
    mapper = Mapper.find_or_create_by!(
      profile: json['profile'], version: json['version'], type: json['type']
    ) do |m|
      logger.info "Creating mapper for: #{manifest.url} #{json.inspect}"
      m.digest = json['digest']
      m.url = json['url']
      m.status = url_found
      m.manifest = manifest
    end

    if mapper.digest != json['digest']
      logger.info "Updating mapper for: #{json.inspect}"
      mapper.config.purge if mapper.config.attached?
      mapper.update(
        digest: json['digest'],
        url: json['url'],
        status: url_found
      )
    end
    mapper.update(enabled: json['enabled']) if mapper.enabled != json['enabled']
    return mapper if mapper.config.attached? || !url_found

    mapper.download
  end

  private

  def set_title
    self.title = "#{type} (#{profile}-#{version})"
  end
end
