# frozen_string_literal: true

module ConnectionStatus
  extend ActiveSupport::Concern

  def connection_is_active?
    if batch && !batch.connection.authorized?
      errors.add(:verify_error, 'connection or user account lookup failed')
    end
  end
end
