module Antfarm
  module Models
    class EthIf < ActiveRecord::Base
      has_many   :tags,   as: :taggable
      has_many   :ip_ifs, class_name: 'IPIf', dependent: :destroy
      belongs_to :node

      accepts_nested_attributes_for :ip_ifs
      accepts_nested_attributes_for :node

      before_validation :set_attributes_from_store

      validates   :certainty_factor, presence:    true
      validates   :address,          uniqueness:  true,
                                     allow_nil:   true,
                                     allow_blank: true
      before_save :clamp_certainty_factor

      #######
      private
      #######

      def set_attributes_from_store
        unless Antfarm.store.eth_if_node.nil?
          self.node ||= Antfarm.store.eth_if_node
        end

        unless Antfarm.store.eth_if_cf.nil?
          self.certainty_factor ||= Antfarm.store.eth_if_cf
        end

        unless Antfarm.store.eth_if_address.nil?
          self.address ||= Antfarm.store.eth_if_address
        end

        return true
      end

      def clamp_certainty_factor
        self.certainty_factor = Antfarm.clamp(self.certainty_factor)
      end
    end
  end
end
