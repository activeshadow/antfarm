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
    class EthIf < ActiveRecord::Base
      belongs_to :l2_if

      before_validation :create_l2_if, on: :create

      validates :address, :presence => true,
                          :format   => { :with => /([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}/i }
      validates :l2_if,   :presence => true

      #######
      private
      #######

      def create_l2_if
        unless self.l2_if
          layer2_interface = L2If.new certainty_factor: Antfarm.config.certainty_factor
          if layer2_interface.save
            Antfarm.log :info, 'EthIf: Created Layer 2 Interface'
          else
            Antfarm.log :warn, 'EthIf: Errors occured while creating Layer 2 Interface'
            layer2_interface.errors.full_messages do |msg|
              Antfarm.log :warn, msg
            end
          end

          self.l2_if = layer2_interface
        end
      end
    end
  end
end
