module Antfarm
  module Models
    class Node < ActiveRecord::Base
      has_many :tags,    as: :taggable
      has_many :eth_ifs, dependent: :destroy
      has_many :ip_ifs,  through: :eth_ifs, class_name: 'IPIf'

      accepts_nested_attributes_for :eth_ifs
      accepts_nested_attributes_for :ip_ifs

      before_validation :set_attributes_from_store

      validates   :certainty_factor, presence:    true
      validates   :name,             uniqueness:  true,
                                     allow_nil:   true,
                                     allow_blank: true
      before_save :clamp_certainty_factor

      def merge_from(node)
        node.eth_ifs.each { |iface| iface.node = self }
        Node.destroy(node.id)
      end

      #######
      private
      #######

      def set_attributes_from_store
        unless Antfarm.store.node_cf.nil?
          self.certainty_factor ||= Antfarm.store.node_cf
        end

        unless Antfarm.store.node_cf.nil?
          self.name ||= Antfarm.store.node_name
        end

        unless Antfarm.store.node_cf.nil?
          self.device_type ||= Antfarm.store.node_device_type
        end

        return true
      end

      def clamp_certainty_factor
        self.certainty_factor = Antfarm.clamp(self.certainty_factor)
      end
    end
  end
end
