require 'test_helper'

class L3IfTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :l3iface, :certainty_factor => nil
    end

    assert !Fabricate.build(:l3iface, :certainty_factor => nil).valid?
  end

  test 'correctly clamps certainty factor' do
    iface = Fabricate :l3iface, :certainty_factor => 1.15
    assert_equal 1.0, iface.certainty_factor
    iface = Fabricate :l3iface
    assert_equal 0.5, iface.certainty_factor
    iface = Fabricate :l3iface, :certainty_factor => -1.15
    assert_equal -1.0, iface.certainty_factor
  end

  test 'allows tags to be added via taggable association' do
    iface = Fabricate :l3iface

    assert iface.tags.count.zero?
    iface.tags.create(:name => 'USA')
    assert iface.tags.count == 1
    assert iface.tags.first.persisted?
    assert iface.tags.first.name == 'USA'
    assert Tag.count == 1
  end
end
