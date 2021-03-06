# frozen_string_literal: true

# This service keeps track of record mapping results in between the process and transfer steps
#   by cacheing the necessary pieces of info
class RecordCacheService
  attr_reader :batch, :client, :namespace
  NAMESPACE = 'processed'
  KEEP = 1.day

  # given namespace (scoped to base_uri) do we need a cleverer cache key?
  def initialize(batch:)
    @batch = batch
    @client = @batch.connection.client
    mapper = get_mapper
    @service_type = mapper['config']['service_type']
    @type = mapper['config']['service_path']
    @subtype = mapper['config']['authority_subtype']
    
    # @namespace = @client.config.base_uri
  end

  def cache_processed(rownum, row_occ, result)
    hash = {
      'xml' => result.xml,
      'id' => result.identifier,
      'status' => result.record_status,
    }
    existing = {
      'csid' => result.csid,
      'uri' => result.uri,
      'refname' => result.refname
    }
    hash = hash.merge(existing) if result.record_status == :existing

    Rails.cache.write(build_key(rownum, row_occ), hash, namespace: NAMESPACE, expires_in: KEEP)
  end

  def retrieve_cached(rownum, row_occ)
    Rails.cache.read(build_key(rownum, row_occ), namespace: NAMESPACE)
  end

  private

  def build_key(rownum, row_occ)
    "#{batch.id}.#{rownum}.#{row_occ}"
  end

  def get_mapper
    Rails.cache.fetch(batch.mapper.title, namespace: 'mapper', expires_in: 1.day) do
      JSON.parse(batch.mapper.config.download)
    end
  end
end
