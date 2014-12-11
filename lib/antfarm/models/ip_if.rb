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
      has_many   :tags, as: :taggable
      belongs_to :eth_if

      before_validation :set_attributes_from_store

      validates    :certainty_factor, presence:   true
      validates    :address,          presence:   true,
                                      uniqueness: true
      validates    :virtual,          inclusion:  {in: [true,false]}
      before_save  :clamp_certainty_factor
      after_create :create_ip_net

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
      end

      def address=(address)
        unless address.nil?
          addr, @prefix = address.split('/')
          @prefix ||= 32
          write_attribute(:address, addr)
        end
      end

      def network
        IPNet.network_containing(self.address)
      end

      #######
      private
      #######

      def set_attributes_from_store
        unless Antfarm.store.ip_if_eth_if.nil?
          self.eth_if ||= Antfarm.store.ip_if_eth_if
        end

        unless Antfarm.store.ip_if_cf.nil?
          self.certainty_factor ||= Antfarm.store.ip_if_cf
        end

        unless Antfarm.store.ip_if_address.nil?
          self.address ||= Antfarm.store.ip_if_address
        end

        unless Antfarm.store.ip_if_virtual.nil?
          self.virtual ||= Antfarm.store.ip_if_virtual
        end
      end

      def clamp_certainty_factor
        self.certainty_factor = Antfarm.clamp(self.certainty_factor)
      end

      # Create an IP Network (and its associated L3 Network) that would contain
      # the IP address provided for this IP Interface model unless one already
      # exists.
      def create_ip_net
        # Check to see if a network exists that contains this address.
        # If not, create a small one that does.
        unless IPNet.network_containing("#{self.address}/#{@prefix}")
          if @prefix == 32 # no subnet data provided
            @prefix = Antfarm.config.prefix # defaults to /30
            certainty_factor = Antfarm::CF_LIKELY_FALSE
          else
            certainty_factor = Antfarm::CF_PROVEN_TRUE
          end

          IPNet.create address: "#{self.address}/#{@prefix}"
          Antfarm.log :info, 'IPIf: Created Layer 3 Network'
        end
      end
    end
  end
end
