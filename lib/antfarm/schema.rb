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

ActiveRecord::Schema.define(:version => 1) do
  create_table 'nodes', :force => true do |t|
    t.float  'certainty_factor', :null => false
    t.string 'name'
    t.string 'device_type'
  end

  create_table 'l2_ifs', :force => true do |t|
    t.integer 'node_id'
    t.float   'certainty_factor', :null => false
    t.string  'media_type'
  end

  create_table 'eth_ifs', :force => true do |t|
    t.integer 'l2_if_id', :null => false
    t.macaddr 'address',  :null => false
  end

  create_table 'l3_ifs', :force => true do |t|
    t.integer 'l2_if_id'
    t.float   'certainty_factor', :null => false
    t.string  'protocol'
  end

  create_table 'ip_ifs', :force => true do |t|
    t.integer 'l3_if_id',                   :null => false
    t.inet    'address',                    :null => false
    t.boolean 'virtual', :default => false, :null => false
  end

  create_table 'l3_nets', :force => true do |t|
    t.float  'certainty_factor', :null => false
    t.string 'protocol'
  end

  create_table 'ip_nets', :force => true do |t|
    t.integer 'l3_net_id', :null => false
    t.cidr    'address',   :null => false
  end

=begin
  create_table 'actions', :force => true do |t|
    t.string 'tool'
    t.string 'description'
    t.string 'start'
    t.string 'end'
  end

  create_table 'os', :force => true do |t|
    t.integer 'action_id'
    t.integer 'node_id',          :null => false
    t.float   'certainty_factor', :null => false
    t.text    'fingerprint'
  end

  create_table 'services', :force => true do |t|
    t.integer 'action_id'
    t.integer 'node_id',          :null => false
    t.float   'certainty_factor', :null => false
    t.string  'protocol'
    t.integer 'port'
    t.text    'name'
  end

  create_table 'connections', :force => true do |t|
    t.integer 'src_id', :null => false
    t.integer 'dst_id', :null => false
    t.string  'description'
    t.integer 'src_port'
    t.integer 'dst_port'
    t.string  'timestamp'
  end
=end

  create_table 'tags', :force => true do |t|
    t.string  'name',          :null => false
    t.integer 'taggable_id',   :null => false
    t.string  'taggable_type', :null => false
  end
end
