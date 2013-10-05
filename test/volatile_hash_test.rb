require_relative './test_helper'

class TestVolatileHash < Minitest::Test
  def test_delete_value
    cache = VolatileHash.new(:strategy => 'ttl', :ttl => 5.0)
    assert_equal nil, cache[:x]
    x = Object.new
    cache[:x] = x
    assert_equal x, cache[:x]
    cache[:x] = nil
    assert_equal nil, cache[:x]
  end
end
