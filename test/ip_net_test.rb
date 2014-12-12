require 'test_helper'

class IPNetTest < TestCase
  include Antfarm::Models

  test 'fails with loopback address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IPNet.create! certainty_factor: 0.0, address: '127.0.0.0/8'
    end
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IPNet.create! certainty_factor: 0.0, address: '276.87.355.0/24'
    end
  end

  test 'merges existing networks that are subnetworks' do
    ip_net1 = IPNet.create! certainty_factor: 0.0, address: '192.168.0.100/30'
    assert_equal 1, IPNet.count

    ip_net2 = IPNet.create! certainty_factor: 0.0, address: '192.168.0.0/24'
    assert_equal 1, IPNet.count

    assert_raises(ActiveRecord::RecordNotFound) do
      ip_net1.reload
    end
  end

  test 'correctly merges networks after a new network is created' do
    IPNet.create! certainty_factor: 0.0, address: '192.168.1.0/24'
    assert_equal 1, IPNet.count

    IPNet.create! certainty_factor: 1.0, address: '192.168.1.0/27'
    assert_equal 1, IPNet.count
    assert_equal '192.168.1.0/27', IPNet.first.address.to_cidr_string

    IPNet.create! certainty_factor: -0.5, address: '192.168.1.0/30'
    assert_equal 1, IPNet.count
    assert_equal '192.168.1.0/27', IPNet.first.address.to_cidr_string

    IPNet.create! certainty_factor: 1.0, address: '192.168.1.0/24'
    assert_equal 1, IPNet.count
    assert_equal '192.168.1.0/24', IPNet.first.address.to_cidr_string
  end
end
