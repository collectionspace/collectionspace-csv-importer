# frozen_string_literal: true

# This service keeps track of record mapping results in between the process and transfer steps
#   by caching the necessary pieces of info
class RecordCacheService
  NAMESPACE = 'processed'
  KEEP = 1.day

  def initialize(batch_id:)
    @batch = batch_id
  end

  def cache_processed(row_occ, result, bloburi = nil)
    hash = build_hash(result, bloburi)
    Rails.cache.write(build_key(row_occ), hash, namespace: NAMESPACE, expires_in: KEEP)
  end

  def retrieve_cached(row_occ)
    Rails.cache.read(build_key(row_occ), namespace: NAMESPACE)
  end

  private

  def build_hash(result, bloburi)
    hash = {
      'xml' => result.xml,
      'id' => result.identifier,
      'status' => result.record_status
    }
    hash = merge_existing_record_data(result, hash) if result.record_status == :existing
    return hash unless bloburi

    hash['bloburi'] = bloburi
    hash
  end

  def build_key(row_occ)
    "#{@batch}.#{row_occ}"
  end

  def merge_existing_record_data(result, hash)
    hash = hash.merge({
                        'csid' => result.csid,
                        'uri' => result.uri,
                        'refname' => result.refname
                      })
    hash
  end
end
