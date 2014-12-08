require 'test_helper'

class IPAddrTest < TestCase
  test 'tracks provided netmask' do
    assert_equal IPAddr.new('255.0.0.0'),       IPAddr.new('192.168.1.1/8').netmask
    assert_equal IPAddr.new('255.255.0.0'),     IPAddr.new('192.168.1.1/16').netmask
    assert_equal IPAddr.new('255.255.255.0'),   IPAddr.new('192.168.1.1/24').netmask
    assert_equal IPAddr.new('255.255.255.224'), IPAddr.new('192.168.1.1/27').netmask
  end

  test 'correctly determines CIDR length' do
    assert_equal 8,  IPAddr.new('192.168.1.1/8').cidr
    assert_equal 16, IPAddr.new('192.168.1.1/16').cidr
    assert_equal 24, IPAddr.new('192.168.1.1/24').cidr
    assert_equal 27, IPAddr.new('192.168.1.1/27').cidr
  end

  test 'correctly provides CIDR string' do
    assert_equal '192.0.0.0/8',     IPAddr.new('192.168.1.1/8').to_cidr_string
    assert_equal '192.168.0.0/16',  IPAddr.new('192.168.1.1/16').to_cidr_string
    assert_equal '192.168.1.0/24',  IPAddr.new('192.168.1.1/24').to_cidr_string
    assert_equal '192.168.1.32/27', IPAddr.new('192.168.1.33/27').to_cidr_string
  end

  test 'correctly determines broadcast address' do
    assert_equal IPAddr.new('192.255.255.255'), IPAddr.new('192.168.1.1/8').broadcast
    assert_equal IPAddr.new('192.168.255.255'), IPAddr.new('192.168.1.1/16').broadcast
    assert_equal IPAddr.new('192.168.1.255'),   IPAddr.new('192.168.1.1/24').broadcast
    assert_equal IPAddr.new('192.168.1.31'),    IPAddr.new('192.168.1.1/27').broadcast
  end

  test 'correctly detects loopback address' do
    assert  IPAddr.new('127.0.0.1').loopback?
    assert  IPAddr.new('127.127.127.254').loopback?
    assert !IPAddr.new('128.1.1.1').loopback?
  end

  test 'correctly detects private address' do
    assert  IPAddr.new('192.168.0.1').private?
    assert  IPAddr.new('192.168.255.254').private?
    assert  IPAddr.new('172.16.0.1').private?
    assert  IPAddr.new('172.16.31.254').private?
    assert  IPAddr.new('10.0.0.1').private?
    assert  IPAddr.new('10.255.255.254').private?
    assert !IPAddr.new('172.32.1.1').private?
  end

  test 'correctly detects multicast address' do
    assert  IPAddr.new('224.0.0.1').multicast?
    assert  IPAddr.new('224.239.255.254').multicast?
    assert !IPAddr.new('240.0.0.1').multicast?
  end

  test 'correctly detects if an address is in a network' do
    assert  IPAddr.new('192.168.1.0/27').include?(IPAddr.new('192.168.1.1'))
    assert  IPAddr.new('192.168.1.0/27').include?(IPAddr.new('192.168.1.30'))
    assert !IPAddr.new('192.168.1.0/27').include?(IPAddr.new('192.168.1.33'))
  end

  test 'correctly detects if a network is in another network' do
    assert  IPAddr.new('192.168.1.0/24').include?(IPAddr.new('192.168.1.0/27'))
    assert !IPAddr.new('192.168.1.0/27').include?(IPAddr.new('192.168.1.0/24'))
  end
end
