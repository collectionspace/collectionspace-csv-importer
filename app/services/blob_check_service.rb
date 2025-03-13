# frozen_string_literal: true

# This service checks existing CS media records to see if they already have a blob
#   attached
class BlobCheckService
  NO_BLOB_MSG = /get failed on org\.collectionspace\.services\.(restricted|)media\.(Restricted|)MediaResource csid=null/

  def initialize(client:)
    @client = client
  end

  # uri : from the cached data hash of an existing record
  def status(uri:)
    response = @client.get("#{uri}/blob")
    return :present if response.result.success?

    return :absent if response.parsed.match?(NO_BLOB_MSG)

    return :unknown
  end
end
