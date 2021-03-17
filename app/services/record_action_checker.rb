# frozen_string_literal: true

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
