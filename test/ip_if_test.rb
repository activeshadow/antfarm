require 'test_helper'

class IPIfTest < TestCase
  include Antfarm::Models

  test 'fails with no address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :address => nil
    end

    assert !Fabricate.build(:ipiface, :address => nil).valid?
  end

  test 'fails with loopback address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :address => '127.0.0.1'
    end

    assert !Fabricate.build(:ipiface, :address => '127.0.0.1').valid?
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :address => '276.87.355.4'
    end

    assert !Fabricate.build(:ipiface, :address => '276.87.355.4').valid?
  end

  test 'fails with duplicate public address' do
    Fabricate :ipiface, :address => '246.87.155.4'
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :address => '246.87.155.4'
    end
  end

  test 'migrates IP interface to larger network when created' do
    iface1 = Fabricate :ipiface, :address => '192.168.0.100/29'
    iface2 = Fabricate :ipiface, :address => '192.168.0.1/24'

    iface1.reload

    assert_equal iface2.l3_if.l3_net, iface1.l3_if.l3_net
  end

  test 'creates IP network and merges networks and interfaces' do
    Fabricate :ipnet, :address => '192.168.101.0/29'
    assert_equal 1, L3Net.count

    iface = Fabricate :ipiface, :address => '192.168.101.4/24'

    assert_equal 1, L3Net.count
    assert_equal '192.168.101.0/24', L3Net.first.ip_net.address
    assert_equal L3Net.first, iface.l3_if.l3_net
  end
end
