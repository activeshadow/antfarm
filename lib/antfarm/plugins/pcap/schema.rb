ActiveRecord::Schema.define do
  create_table 'connections', :force => true do |t|
    t.integer 'src_id', :null => false
    t.integer 'dst_id', :null => false
    t.string  'description'
    t.integer 'src_port'
    t.integer 'dst_port'
    t.string  'timestamp'
  end
end
