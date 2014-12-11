require 'test_helper'

class VersionTest < TestCase
  test 'correct version' do
    assert '2.0.0', Antfarm.version
  end
end
