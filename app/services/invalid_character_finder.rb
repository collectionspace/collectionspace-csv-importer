# frozen_string_literal: true

# This service returns non-UTF-8 characters from an uploaded CSV, with their
#   surrounding context, so that users can find the characters that need to
#   be replaced
class InvalidCharacterFinder
  def initialize(csv_string)
    @csv_string = csv_string
    @char_ct = csv_string.length
    @context_chars = 20
    @min_idx = context_chars - 1
    @max_idx = char_ct - context_chars - 1
    @replacement_char = '�'
  end

  # @return [Array<String>]
  def call
    invalid_char_indexes.values
                        .map do |idx|
      [context(idx, :before),
       replacement_char,
       context(idx, :after)].join
    end
  end

  private

  attr_reader :csv_string, :char_ct, :context_chars, :min_idx, :max_idx,
              :replacement_char

  # @return [Hash<String=>Integer>] unique invalid characters in CSV as keys;
  #   index of first occurrence of the string as values
  def invalid_char_indexes
    csv_string.chars
              .map.with_index { |char, idx| char.is_utf8? ? nil : [char, idx] }
              .compact
              .group_by { |arr| arr[0] }
              .values
              .map { |arr| arr.first }
              .to_h
  end

  # @return [String] with any invalid UTF-8 characters occurring in the context
  #   replaced by replacement_char
  def context(idx, mode)
    range = if mode == :before
              Range.new(min(idx), idx - 1)
            else
              Range.new(idx + 1, max(idx))
            end
    csv_string.slice(range)
              .chars
              .map { |char| char.is_utf8? ? char : replacement_char }
  end

  def min(idx)
    idx < min_idx ? 0 : idx - context_chars
  end

  def max(idx)
    idx > max_idx ? char_ct - 1 : idx + context_chars
  end
end
