module Antfarm
  module Models
    class Service < ActiveRecord::Base
      belongs_to :action
      belongs_to :node

      validates :node,             :presence => true
      validates :certainty_factor, :presence => true

      before_save :clamp_certainty_factor

      #######
      private
      #######

      def clamp_certainty_factor
        self.certainty_factor = Antfarm.clamp(self.certainty_factor)
      end
    end
  end
end
