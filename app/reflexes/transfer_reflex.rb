# frozen_string_literal: true

class TransferReflex < ApplicationReflex
  def delete
    @selected ||= {}
    @selected[:delete] = element.checked
  end

  def update
    @selected ||= {}
    @selected[:update] = element.checked
  end
end
