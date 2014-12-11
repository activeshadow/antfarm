require 'test_helper'

class EthIfTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      EthIf.create!
    end
    assert !EthIf.new.valid?
  end

  test 'saves with no address' do
    assert_equal 0, EthIf.count
    EthIf.create certainty_factor: 0.5
    assert_equal 1, EthIf.count
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::StatementInvalid) do
      EthIf.create certainty_factor: 0.5, address: '00:00:00:00:00:0Z'
    end
  end

  test 'fails with duplicate address' do
    Antfarm.store.eth_if_cf = 0.0
    EthIf.create! address: '00:00:00:11:22:33'
    assert_raises(ActiveRecord::RecordInvalid) do
      EthIf.create! address: '00:00:00:11:22:33'
    end
  end
end
