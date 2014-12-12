module Antfarm
  module Models
    class IPNet < ActiveRecord::Base
      has_many :tags, as: :taggable

      before_validation :set_attributes_from_store

      validates    :certainty_factor, presence:   true
      validates    :address,          presence:   true,
                                      uniqueness: true
      before_save  :clamp_certainty_factor
      after_create :merge

      # Validate data for requirements before saving network to the database.
      #
      # Was using validate_on_create, but decided that these restraints should
      # occur on anything saved to the database at any time, including a create
      # and an update.
      validates_each :address do |record, attr, value|
        # Don't save the network if it's a loopback network.
        if value and value.loopback?
          record.errors.add(:address, 'loopback address not allowed')
        end
      end

      #######
      private
      #######

      def set_attributes_from_store
        Antfarm.log :debug, 'IPNet: setting attributes'

        unless Antfarm.store.ip_net_cf.nil?
          self.certainty_factor ||= Antfarm.store.ip_net_cf
          Antfarm.log :debug, "IPNet: CF set to #{self.certainty_factor}"
        end

        unless Antfarm.store.ip_net_address.nil?
          self.address ||= Antfarm.store.ip_net_address
          Antfarm.log :debug, "IPNet: address set to #{self.address}"
        end

        return true
      end

      def clamp_certainty_factor
        self.certainty_factor = Antfarm.clamp(self.certainty_factor)
      end

      # Merge any sub-networks of this network into this network. Given we're
      # depending on PostgreSQL now to handle network detection and
      # containment, this simply means destroying any sub-networks.
      def merge
        Antfarm.log :info, "Merge called for #{self.address}"

        # a network already exists that contains this network...
        if parent = IPNet.network_containing(self.address)
          unless parent.address.eql?(self.address)
            if parent.certainty_factor >= self.certainty_factor
              self.destroy
            else
              parent.destroy
            end
          end
        end

        # networks exist that this network contains...
        for child in IPNet.networks_contained_within(self.address)
          unless child.address.eql?(self.address)
            if self.certainty_factor >= child.certainty_factor
              child.destroy
            else
              self.destroy
            end
          end
        end
      end

      # Find the IP network the given network is a sub_network of, if one
      # exists.
      def self.network_containing(ip_net)
        Antfarm.log :debug, "IPNet: checking to see if #{ip_net.inspect} exists..."
        ip_net  = IPAddr.new(ip_net) if ip_net.is_a?(String)
        ip_nets = IPNet.where("address >>= ?", ip_net.to_cidr_string)
        return ip_nets.first # TODO: what if there's more than one?
      end

      class << self
        # Find the IP network with the given address.  Aliasing
        # network_containing as network_addressed here because if a network
        # already exists that encompasses the given network, we want to
        # automatically use that network instead.
        alias_method :network_addressed, :network_containing
      end

      # Find any IP networks that are sub_networks of the given network.
      def self.networks_contained_within(ip_net)
        ip_net = IPAddr.new(ip_net) if ip_net.is_a?(String)
        return IPNet.where("address <<= ?", ip_net.to_cidr_string)
      end
    end
  end
end
