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
    # Data model for an IP Interface
    #
    # When IP Interfaces are saved (create/update), the <tt>address</tt>
    # attribute is validated and checks are run to see if a L3 Network exists
    # to associate the interface to. If one does not already exist, a new L3
    # Network model is created and assocated with the IP Interface. The rules
    # for determining what size of new L3 Network to create are described as
    # follows:
    #
    # If subnet information is included in the IP address provided, then that
    # is used to create the new L3 Network.
    #
    # Otherwise, a default subnet prefix (usually /30) is used to create the
    # new L3 Network. If, when the new L3 Network is created, it results in the
    # address being a network address rather than a host address (for example,
    # 192.168.0.100/30), the prefix is changed to /29. One can override the
    # default subnet prefix to use when creating new L3 Networks by wrapping
    # the creation code with the <tt>IPIf.execute_with_prefix</tt> call.
    #
    #    Antfarm::Models::IPIf.execute_with_prefix(24) do
    #      Antfarm::Models::IPIf.new(:address => '192.168.0.100')
    #    end
    class IPIf < ActiveRecord::Base
      belongs_to :l3_if #, inverse_of: :ip_if

      before_validation :create_l3_if, on: :create

      # TODO: figure out why it fails when `after_save` is used...
      #
      # Recursion seems to occur in the `associate_l3_net` method when called
      # after every save... it's like the call to update attributes on the L3
      # Interface for this IP Interface causes this model to be saved again,
      # therein causing recursion since the `associate_l3_net` method is called
      # once again.
      after_create :create_ip_net
#     after_create :associate_l3_net

      validates :address, :presence => true
      validates :l3_if,   :presence => true

      # Validate data for requirements before saving interface to the database.
      #
      # Was using validate_on_create, but decided that restraints should occur
      # on anything saved to the database at any time, including a create and an
      # update.
      validates_each :address do |record, attr, value|
        # Don't save the interface if it's a loopback address.
        if value and value.loopback?
          record.errors.add(attr, 'loopback address not allowed')
        end

=begin
        if interface = IPIf.find_by_address(value)
          interface.update_attribute :address, value
          message = "#{value} already exists, but a new IP Network was created"
          record.errors.add(:address, message)
          Antfarm.log :info, message
        end
=end
      end

      #######
      private
      #######

      # Create an IP Network (and its associated L3 Network) that would contain
      # the IP address provided for this IP Interface model unless one already
      # exists.
      def create_ip_net
        # Check to see if a network exists that contains this address.
        # If not, create a small one that does.
        unless IPNet.network_containing(self.address.to_cidr_string)
          if self.address.prefix == 32 # no subnet data provided
            self.address.prefix = Antfarm.config.prefix # defaults to /30

            # address for this interface shouldn't be a network address...
            if self.address == self.address.network
              self.address.prefix = Antfarm.config.prefix - 1
            end

            certainty_factor = Antfarm::CF_LIKELY_FALSE
          else
            certainty_factor = Antfarm::CF_PROVEN_TRUE
          end

          IPNet.create address: self.address.network.to_cidr_string
        end
      end

      # Based on the current value of the <tt>address</tt> attribute, checks to
      # see if an existing L3 Network would contain the IP address. If so, this
      # model is associated with the L3 Network.
      def associate_l3_net
        if layer3_network = L3Net.network_containing(self.address)
          self.l3_if.update_attribute :l3_net, layer3_network
        end
      end

      def create_l3_if
        unless self.l3_if
          layer3_interface = L3If.new certainty_factor: Antfarm.config.certainty_factor
          if layer3_interface.save
            Antfarm.log :info, 'IPIf: Created Layer 3 Interface'
          else
            Antfarm.log :warn, 'IPIf: Errors occured while creating Layer 3 Interface'
            layer3_interface.errors.full_messages do |msg|
              Antfarm.log :warn, msg
            end
          end

          self.l3_if = layer3_interface
        end
      end
    end
  end
end
