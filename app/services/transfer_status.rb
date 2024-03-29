# frozen_string_literal: true

class TransferStatus
  attr_accessor :success, :message, :uri, :action, :warnings
  def initialize(success: false, message: '', uri: nil, action: nil)
    @success = success
    @message = message
    @uri = uri
    @action = action
    @warnings =[]
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

  def add_warning(message)
    @warnings << message
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
