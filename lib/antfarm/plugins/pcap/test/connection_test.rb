require 'test_helper'

class ConnectionTest < TestCase
  include Antfarm::Models

  test 'fails with no source present' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Connection.create! :dst => IPIf.new
    end
  end

  test 'fails with no target present' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Connection.create! :src => IPIf.new
    end
  end
end
