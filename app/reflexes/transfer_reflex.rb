# frozen_string_literal: true

class TransferReflex < ApplicationReflex
  def create
    batch_fingerprint = element.dataset['batch_fingerprint']
    session[batch_fingerprint][:create] = element.checked
    session[batch_fingerprint][:update] = session[batch_fingerprint].fetch(:update, false)
  end

  def delete
    batch_fingerprint = element.dataset['batch_fingerprint']
    session[batch_fingerprint][:delete] = element.checked
  end

  def update
    batch_fingerprint = element.dataset['batch_fingerprint']
    session[batch_fingerprint][:create] = session[batch_fingerprint].fetch(:create, false)
    session[batch_fingerprint][:update] = element.checked
  end
end
