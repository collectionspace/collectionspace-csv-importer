# frozen_string_literal: true

require 'test_helper'

class InvalidCharacterFinderTest < ActiveSupport::TestCase
  test 'can return invalid characters in context' do
    str = <<~STR
      Nis\x95i mihi \x95Phaedrum, inquam, tu mentitum aut Zenonem putas,
      quorum utrumque audivi, cum mihi nihil sane praeter sedulitatem
      probarent, omnes mihi Epicuri sententiae satis notae sunt. atque
      eos, quos nominavi, cum Attico \x81 nostro frequenter audivi, cum
      miraretur ille quidem utrumque, Phaedrum autem etiam amaret,
      cotidieque inter nos ea, quae audiebamus, conferebamus, neque erat
      umquam controversia, quid ego intellegerem, sed quid prob\x85arem.
    STR

    result = InvalidCharacterFinder.new(str.chomp).call
    expected = [
      'Nis�i mihi �Phaedrum, in',
      'ominavi, cum Attico � nostro frequenter a',
      'gerem, sed quid prob�arem.'
    ]
    assert_equal(expected, result)
  end
end
