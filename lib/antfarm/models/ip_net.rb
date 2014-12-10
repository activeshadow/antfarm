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
    class IPNet < ActiveRecord::Base
      belongs_to :l3_net

      before_validation :create_l3_net, on: :create
      after_create      :merge

      validates :address, presence: true
      validates :l3_net,  presence: true

      # Validate data for requirements before saving network to the database.
      #
      # Was using validate_on_create, but decided that these restraints should
      # occur on anything saved to the database at any time, including a create
      # and an update.
      validates_each :address do |record, attr, value|
        # Don't save the network if it's a loopback network.
        if value and value.loopback?
          record.errors.add(:address, "loopback address not allowed")
        end
      end

      #######
      private
      #######

      # Merge any sub-networks of this network into this network
      def merge(merge_certainty_factor = Antfarm.config.certainty_factor)
        Antfarm.log :info, "Merge called for #{self.address}"

        for sub_network in IPNet.networks_contained_within(self.address)
          unless sub_network.address.eql?(self.address)
            # TODO: update network's certainty factor using sub_network's
            #       certainty factor.
#           merge_certainty_factor = Antfarm.clamp(merge_certainty_factor)
#           network.save!

            # Because of :dependent => :destroy above, calling destroy here will
            # also cause destroy to be called on ip_net
            sub_network.l3_net.destroy
          end
        end
      end

      # Find the IP network with the given address.
      def self.network_addressed(ip_net)
        # Calling network_containing here because if a network already exists
        # that encompasses the given network, we want to automatically use that
        # network instead.
        #
        # TODO: figure out how to use alias with class methods
        self.network_containing(ip_net)
      end

      # Find the IP network the given network is a sub_network of, if one
      # exists.
      def self.network_containing(ip_net)
        ip_net  = IPAddr.new(ip_net) if ip_net.is_a?(String)
        ip_nets = IPNet.where("address >>= ?", ip_net.to_cidr_string)
        return ip_nets.first # TODO: what if there's more than one?
      end

      # Find any IP networks that are sub_networks of the given network.
      def self.networks_contained_within(ip_net)
        ip_net = IPAddr.new(ip_net) if ip_net.is_a?(String)
        return IPNet.where("address <<= ?", ip_net.to_cidr_string)
      end

      def create_l3_net
        unless self.l3_net
          layer3_network = L3Net.new certainty_factor: Antfarm.config.certainty_factor
          if layer3_network.save
            Antfarm.log :info, 'IPNet: Created Layer 3 Network'
          else
            Antfarm.log :warn, 'IPNet: Errors occured while creating Layer 3 Network'
            layer3_network.errors.full_messages do |msg|
              Antfarm.log :warn, msg
            end
          end

          self.l3_net = layer3_network
        end
      end
    end
  end
end
