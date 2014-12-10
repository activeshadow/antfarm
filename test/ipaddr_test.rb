require 'test_helper'

class IPAddrTest < TestCase
  test 'correctly determines prefix length' do
    assert_equal 8,  IPAddr.new('192.168.1.1/8').prefix
    assert_equal 16, IPAddr.new('192.168.1.1/16').prefix
    assert_equal 24, IPAddr.new('192.168.1.1/24').prefix
    assert_equal 27, IPAddr.new('192.168.1.1/27').prefix
  end

  test 'correctly modifies prefix length' do
    addr = IPAddr.new('192.168.1.1')
    assert_equal 32, addr.prefix

    addr.prefix = 30
    assert_equal 30, addr.prefix
    assert_equal '192.168.1.0/30', addr.to_cidr_string
  end

  test 'correctly provides CIDR string' do
    assert_equal '192.168.1.1/32',  IPAddr.new('192.168.1.1').to_cidr_string
    assert_equal '192.0.0.0/8',     IPAddr.new('192.168.1.1/8').to_cidr_string
    assert_equal '192.168.0.0/16',  IPAddr.new('192.168.1.1/16').to_cidr_string
    assert_equal '192.168.1.0/24',  IPAddr.new('192.168.1.1/24').to_cidr_string
    assert_equal '192.168.1.32/27', IPAddr.new('192.168.1.33/27').to_cidr_string
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
end
