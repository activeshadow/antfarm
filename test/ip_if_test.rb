require 'test_helper'

class IPIfTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IPIf.create! address: '192.168.1.1', virtual: false
    end
    assert !IPIf.new(address: '192.68.1.1', virtual: false).valid?
  end

  test 'fails with no address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IPIf.create! certainty_factor: 0.0, virtual: false
    end
    assert !IPIf.new(certainty_factor: 0.0, virtual: false).valid?
  end

  test 'fails with virtual attribute not being set' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IPIf.create! certainty_factor: 0.0, address: '192.68.1.1'
    end
    assert !IPIf.new(certainty_factor: 0.0, address: '192.68.1.1').valid?
  end

  test 'fails with loopback address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IPIf.create! certainty_factor: 0.0, address: '127.0.0.1', virtual: false
    end
    assert !IPIf.new(certainty_factor: 0.0, address: '127.0.0.1', virtual: false).valid?
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IPIf.create! certainty_factor: 0.0, address: '276.87.355.4', virtual: false
    end
  end

  test 'fails with duplicate public address' do
    Antfarm.store.ip_net_cf = 0.0
    IPIf.create! certainty_factor: 0.0, address: '246.87.155.4', virtual: false
    assert_raises(ActiveRecord::RecordInvalid) do
      IPIf.create! certainty_factor: 0.0, address: '246.87.155.4', virtual: false
    end
  end

  test 'migrates IP interface to larger network when created' do
    Antfarm.store.ip_if_cf  = 0.0
    Antfarm.store.ip_net_cf = 0.0

    iface1 = IPIf.create! address: '192.168.0.100/29', virtual: true
    iface2 = IPIf.create! address: '192.168.0.1/24',   virtual: true

    iface1.reload

    assert_equal iface2.network, iface1.network
  end

  test 'creates IP network and merges networks and interfaces' do
    Antfarm.store.ip_if_cf  = 0.0
    Antfarm.store.ip_net_cf = 0.0

    IPNet.create! address: '192.168.101.0/29'
    assert_equal 1, IPNet.count

    iface = IPIf.create! address: '192.168.101.4/24', virtual: true

    assert_equal 1, IPNet.count
    assert_equal '192.168.101.0/24', IPNet.first.address.to_cidr_string
  end
end
