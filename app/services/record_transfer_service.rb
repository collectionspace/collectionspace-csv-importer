# frozen_string_literal: true

# This service handles transfering new, update, and delete records

# Initialized with transfer_step because we need the action_update, action_create, and action_delete
#  attributes of Step::Transfer
# If action_delete = true:
#   - new records are skipped
#   - existing records are transferred as deletes
#   - no create/update actions are taken
# If action_create = true:
#   - record is transferred to CollectionSpace if status = new
# If action_update = true:
#   - record is updated in CollectionSpace if status = existing

# Needs the mapper to get service_type, type, and (if an authority) subtype

class RecordTransferService
  include MediaRectype

  attr_reader :transfer_step, :client, :service_type, :type, :subtype

  def initialize(transfer: transfer_step)
    @transfer_step = transfer
    @batch = transfer.batch
    @client = @batch.connection.client
    mapper = @batch.record_mapper
    @service_type = mapper['config']['service_type']
    @type = mapper['config']['service_path']
    @subtype = mapper['config']['authority_subtype']
    @blob_checker = BlobCheckService.new(client: @client)
  end

  def transfer_record(data)
    # TODO: refactor RecordActionChecker so it can be initialized once per RecordTransferService and
    #   called per record
    checker = RecordActionChecker.new(data['status'], transfer_step)
    if checker.deleteable?
      result = delete_transfer(data)
    elsif checker.createable?
      result = create_transfer(data)
    elsif checker.updateable?
      result = update_transfer(data)
    else
      result = TransferStatus.new(message: 'ERROR: no appropriate transfer action detected for record')
    end
    result
  end

  private


  def params(data)
    return {} unless is_media?(@type)

    return {} if data['bloburi'].blank?

    { query: { 'blobUri' => URI(data['bloburi']) } }
  end


  # @todo make class instance variable?
  def service_path
    if @subtype
      client.service(type: type, subtype: subtype)[:path]
    else
      client.service(type: type)[:path]
    end
  end

  def delete_transfer(data)
    status = TransferStatus.new
    rec_id = data['id']
    uri = data['uri']
    Rails.logger.debug("Deleting record with ID #{rec_id} at path: #{uri}")
    begin
      delete = client.delete(uri)
      if delete.result.success?
        status.good("Deleted #{rec_id}")
        status.set_uri(uri)
        status.set_action('Deleted')
        status
      else
        status.bad("ERROR: #{prettify_client_error(delete.result.body)}")
      end
    rescue StandardError => e
      status.bad("ERROR: Transfer error: #{e.message} at #{e.backtrace.first}")
    end
    status
  end

  def prettify_client_error(message)
    case message
      when /^Delete request failed:.*Cannot delete authority item.*because it still has records in the system that are referencing it/
        'Could not delete because other records in the system are still referencing this authority term'
    else
      message
    end
  end

  def create_transfer(data)
    status = TransferStatus.new
    path = service_path
    rec_id = data['id']
    Rails.logger.debug("Posting new record with ID #{rec_id} at path: #{path}")
    begin
      post = client.post(path, data['xml'], params(data))
      if post.result.success?
        status.good("Created new record for #{rec_id}")
        status.set_uri(post.result.headers['Location'])
        status.set_action('Created')
        status
      else
        status.bad("ERROR: Client response: #{post.result.body}")
      end
    rescue StandardError => e
      status.bad("ERROR: Error in transfer: #{e.message} at #{e.backtrace.first}")
    end
    status
  end

  def update_transfer(data)
    status = TransferStatus.new
    rec_id = data['id']
    rec_uri = data['uri']

    put_args = [rec_uri, data['xml']]

    case blob_status(data)
    when :present
      status.add_warning('FILE INGEST: Blob already exists on media. No new file was ingested')
    when :absent
      put_args << params(data)
    when :unknown
      status.add_warning('FILE INGEST: Could not determine whether any blob already exists on media. No new file was ingested')
    end

    Rails.logger.debug("Putting updated record with ID #{rec_id} at path: #{rec_uri}")
    begin
      put = client.put(*put_args)
      if put.result.success?
        status.good("Updated record for #{rec_id}")
        status.set_uri("#{client.config.base_uri}#{rec_uri}")
        status.set_action('Updated')
        status
      else
        status.bad("ERROR: Client response: #{put.result.body}")
      end
    rescue StandardError => e
      status.bad("ERROR: Error in transfer: #{e.message} at #{e.backtrace.first}")
    end
    status
  end

  def blob_status(data)
    return :irrelevant unless is_media?(@type)

    return :irrelevant if data['bloburi'].blank?

    @blob_checker.status(uri: data['uri'])
  end
end
