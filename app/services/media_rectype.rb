# frozen_string_literal: true

# Mixin module for checking whether you are working with a media record type
module MediaRectype
  def is_media?(rectype) = %w[media restrictedmedia].include?(rectype)
end
