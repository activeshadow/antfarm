require 'test_helper'

class NodeTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Node.create!
    end
    assert !Node.new.valid?
  end

  test 'correctly sets certainty factor from keystore' do
    Antfarm.store.node_cf = 0.34
    node = Node.create!
    assert_equal 0.34, node.certainty_factor
  end

  test 'correctly clamps certainty factor' do
    node = Node.create certainty_factor: 1.15
    assert_equal 1.0, node.certainty_factor
    node = Node.create certainty_factor: -1.15
    assert_equal -1.0, node.certainty_factor

    Antfarm.store.node_cf = 2.5
    node = Node.create
    assert_equal 1.0, node.certainty_factor
  end

  test 'allows tags to be added via taggable association' do
    node = Node.create! certainty_factor: 0.0

    assert node.tags.count.zero?
    node.tags.create(:name => 'Modbus TCP Master')
    assert node.tags.count == 1
    assert node.tags.first.persisted?
    assert node.tags.first.name == 'Modbus TCP Master'
    assert Tag.count == 1
  end

  test 'fails with duplicate name' do
    Antfarm.store.node_cf = 0.0
    Node.create! name: 'foobar'
    assert_raises(ActiveRecord::RecordInvalid) do
      Node.create! name: 'foobar'
    end
  end
end
