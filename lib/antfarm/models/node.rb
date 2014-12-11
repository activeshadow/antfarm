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
    class Node < ActiveRecord::Base
      has_many :tags,    as: :taggable
      has_many :eth_ifs, dependent: :destroy
      has_many :ip_ifs,  through: :eth_ifs, class_name: 'IPIf'

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
      end

      def clamp_certainty_factor
        self.certainty_factor = Antfarm.clamp(self.certainty_factor)
      end
    end
  end
end
