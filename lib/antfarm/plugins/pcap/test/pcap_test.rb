require 'test_helper'
require 'packetfu/modbus'

class PcapTest < TestCase
  test 'PCAP Parser w/ Modbus PacketFu addition and OUI parser' do
    opts = { :file => "#{File.dirname(__FILE__)}/pcap-parser-test-data.pcap" }

    Antfarm.plugins['pcap'].run(opts)

    src = Antfarm::Models::IPIf.first
    dst = Antfarm::Models::IPIf.last

    assert_equal 'CA:02:03:F8:00:06', src.eth_if.address.upcase
    assert_equal '00:0C:29:CE:53:E6', dst.eth_if.address.upcase

    assert dst.eth_if.tags.map(&:name).include?('VMware, Inc.')

#   assert src.tags.map(&:name).include?('Modbus TCP Master')
#   assert dst.tags.map(&:name).include?('Modbus TCP Slave')

    conn = Antfarm::Models::Connection.first

    assert_equal src, conn.src
    assert_equal dst, conn.dst

    assert_equal 502, conn.dst_port
  end
end
