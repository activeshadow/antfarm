################################################################################
#                                                                              #
# Copyright (2008-2014) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

module Antfarm
  module Models
    class Connection < ActiveRecord::Base
      belongs_to :src, :class_name => "IPIf"
      belongs_to :dst, :class_name => "IPIf"

      validates :src, :presence => true
      validates :dst, :presence => true
    end

    class IPIf < ActiveRecord::Base
      has_many :inbound_connections,  class_name: 'Connection', foreign_key: 'dst_id'
      has_many :outbound_connections, class_name: 'Connection', foreign_key: 'src_id'
    end
  end
end

module Antfarm
  module Pcap
    def self.registered(plugin)
      plugin.name = 'pcap'
      plugin.info = {
        :desc   => 'Parse PCAP data',
        :author => 'Bryan T. Richardson'
      }
      plugin.options = [{
        :name     => 'file',
        :desc     => 'File containing PCAP data',
        :type     => String,
        :required => true
      }]
    end

    def run(opts = Hash.new)
      check_options(opts)

      require 'packetfu/modbus'

      if File.readable?(opts[:file])
        PacketFu::PcapFile.read_packets(opts[:file]) do |pkt|
          if pkt.proto.include?('IP')
            smaddr = pkt.eth_saddr.upcase
            dmaddr = pkt.eth_daddr.upcase
            siaddr = pkt.ip_saddr
            diaddr = pkt.ip_daddr

            src = nil
            dst = nil

            if s_ip_iface = Antfarm::Models::IPIf.find_by(address: siaddr)
              if ethiface = s_ip_iface.eth_if
                if ethiface.certainty_factor < Antfarm::CF_PROVEN_TRUE
                  ethiface.update_attribute :address, smaddr
                end
              else
                s_ip_iface.eth_if.create! address: smaddr
              end

              src = s_ip_iface
            else
              ethiface = EthIf.create!(
                certainty_factor: Antfarm::CF_PROVEN_TRUE,
                address: smaddr,
                tags: [
                  Antfarm::Models::Tag.new(
                    name: Antfarm::OuiParser.get_name(smaddr) || 'Unknown Vendor'
                  )
                ]
              )

              src = ethiface.ip_ifs.create!(
                certainty_factor: Antfarm::CF_PROVEN_TRUE,
                address: siaddr, virtual: false
              )
            end

            if d_ip_iface = Antfarm::Models::IPIf.find_by(address: diaddr)
              if ethiface = d_ip_iface.eth_if
                if ethiface.certainty_factor < Antfarm::CF_PROVEN_TRUE
                  ethiface.update_attribute :address, dmaddr
                end
              else
                d_ip_iface.eth_if.create! address: dmaddr
              end

              dst = d_ip_iface
            else
              ethiface = EthIf.create!(
                certainty_factor: Antfarm::CF_PROVEN_TRUE,
                address: dmaddr,
                tags: [
                  Antfarm::Models::Tag.new(
                    name: Antfarm::OuiParser.get_name(dmaddr) || 'Unknown Vendor'
                  )
                ]
              )

              dst = ethiface.ip_ifs.create!(
                certainty_factor: Antfarm::CF_PROVEN_TRUE,
                address: diaddr, virtual: false
              )
            end

=begin
            if pkt.proto.include?('Modbus')
              if pkt.tcp_src == 502
                src.l2_if.node.tags.find_or_create_by! :name => 'Modbus TCP Slave'
                dst.l2_if.node.tags.find_or_create_by! :name => 'Modbus TCP Master'
              elsif pkt.tcp_dst == 502
                src.l2_if.node.tags.find_or_create_by! :name => 'Modbus TCP Master'
                dst.l2_if.node.tags.find_or_create_by! :name => 'Modbus TCP Slave'
              end
            end
=end

            Antfarm::Models::Connection.create! src: src, dst: dst,
              description: pkt.proto.last,
              src_port:   pkt.proto.include?('TCP') ? pkt.tcp_src : nil,
              dst_port:   pkt.proto.include?('TCP') ? pkt.tcp_dst : nil
          end
        end
      else
        raise "Infput file #{opts[:file]} doesn't exist."
      end
    end
  end
end

Antfarm.register(Antfarm::Pcap)
