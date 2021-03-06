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

class RecordTransferService
  attr_reader :transfer_step, :client, :service_type, :type, :subtype

  # given namespace (scoped to base_uri) do we need a cleverer cache key?
  def initialize(transfer: transfer_step)
    @transfer_step = transfer
    @batch = transfer.batch
    @client = @batch.connection.client
    mapper = get_mapper
    @service_type = mapper['config']['service_type']
    @type = mapper['config']['service_path']
    @subtype = mapper['config']['authority_subtype']
  end

  def transfer_record(data)
    checker = RecordActionChecker.new(data, transfer_step)
    if checker.deleteable?
      result = delete_transfer
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

  def service_path
    if @subtype
      client.service(type: type, subtype: subtype)[:path]
    else
      client.service(type: type)[:path]
    end
  end
  
  def delete_transfer
    TransferStatus.new(message: 'Delete transfer is not yet implemented')
  end

  def create_transfer(data)
    status = TransferStatus.new
    path = service_path
    rec_id = data['id']
    Rails.logger.debug("Posting new record with ID #{rec_id} at path: #{path}")
    begin
      post = client.post(path, data['xml'])
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
    Rails.logger.debug("Putting updated record with ID #{rec_id} at path: #{rec_uri}")
    begin
      put = client.put(rec_uri, data['xml'])
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
  
  def get_mapper
    Rails.cache.fetch(@batch.mapper.title, namespace: 'mapper', expires_in: 1.day) do
      JSON.parse(@batch.mapper.config.download)
    end
  end
end

class RecordActionChecker
  def initialize(cached_data, transfer_step)
    @status = cached_data['status']
    @delete = transfer_step.action_delete
    @create = transfer_step.action_create
    @update = transfer_step.action_update
  end

  def deleteable?
    return false unless @delete 
    return false unless @status == :existing
    true
  end

  def createable?
    return false if @delete #won't create anything if we are deleting
    return false unless @create
    return false unless @status == :new
    true
  end

  def updateable?
    return false if @delete #won't create anything if we are deleting
    return false unless @update
    return false unless @status == :existing
    true
  end
end

class TransferStatus
  attr_accessor :success, :message, :uri, :action
  def initialize(success: false, message: '', uri: nil, action: nil)
    @success = success
    @message = message
    @uri = uri
    @action = action
  end

  def bad(message)
    @success = false
    @message = message
    Rails.logger.error(message)
  end

  def good(message)
    @success = true
    @message = message
    Rails.logger.debug(message)
  end

  def set_uri(uri)
    @uri = uri
  end

  def set_action(action)
    @action = action
  end

  def success?
    @success
  end
end
