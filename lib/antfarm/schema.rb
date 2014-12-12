ActiveRecord::Schema.define do
  create_table 'nodes', :force => true do |t|
    t.float  'certainty_factor', null: false
    t.string 'name'
    t.string 'device_type'
  end

  add_index :nodes, :name, unique: true

  create_table 'eth_ifs', :force => true do |t|
    t.integer 'node_id'
    t.float   'certainty_factor', null: false
    t.macaddr 'address'
  end

  add_index :eth_ifs, :address, unique: true

  create_table 'ip_ifs', :force => true do |t|
    t.integer 'eth_if_id'
    t.float   'certainty_factor', null: false
    t.inet    'address',          null: false
    t.boolean 'virtual',          null: false
  end

  add_index :ip_ifs, :address, unique: true

  create_table 'ip_nets', :force => true do |t|
    t.float 'certainty_factor', null: false
    t.cidr  'address',          null: false
  end

  add_index :ip_nets, :address, unique: true

  create_table 'tags', :force => true do |t|
    t.string  'name',          null: false
    t.integer 'taggable_id',   null: false
    t.string  'taggable_type', null: false
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
=end
end
