require 'test_helper'

class IPNetTest < TestCase
  include Antfarm::Models

  test 'layer 3 network created when not provided' do
    assert Fabricate :ipnet, :l3_net => nil
    assert Fabricate.build(:ipnet, :l3_net => nil).valid?
  end

  test 'layer 3 network provided is used for new IP network' do
    net = Fabricate :l3net
    assert net == Fabricate(:ipnet, :l3_net => net).l3_net
    assert net != Fabricate(:ipnet, :l3_net => nil).l3_net
  end

  test 'fails with loopback address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipnet, :address => '127.0.0.0/8'
    end

    assert !Fabricate.build(:ipnet, :address => '127.0.0.0/8').valid?
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipnet, :address => '276.87.355.0/24'
    end
  end

  test 'merges existing networks that are subnetworks' do
    ip_net1 = Fabricate :ipnet, :address => '192.168.0.100/30'
    assert_equal 1, IPNet.count

    ip_net2 = Fabricate :ipnet, :address => '192.168.0.0/24'
    assert_equal 1, IPNet.count

    # ip_net1 should no longer exist...
    assert_raises(ActiveRecord::RecordNotFound) do
      ip_net1.reload
    end
  end
end
