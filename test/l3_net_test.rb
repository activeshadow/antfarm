require 'test_helper'

class L3NetTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :l3net, :certainty_factor => nil
    end

    assert !Fabricate.build(:l3net, :certainty_factor => nil).valid?
  end

  test 'correctly clamps certainty factor' do
    net = Fabricate :l3net, :certainty_factor => 1.15
    assert_equal 1.0, net.certainty_factor
    net = Fabricate :l3net
    assert_equal 0.5, net.certainty_factor
    net = Fabricate :l3net, :certainty_factor => -1.15
    assert_equal -1.0, net.certainty_factor
  end

  test 'destroys associated IP network object' do
    ip = IPNet.create(address: '192.168.1.0/24')
    l3 = ip.l3_net

    l3.destroy

    assert_raises(ActiveRecord::RecordNotFound) do
      ip.reload
    end
  end

  test 'allows tags to be added via taggable association' do
    net = Fabricate :l3net

    assert net.tags.count.zero?
    net.tags.create(:name => 'Control Center')
    assert net.tags.count == 1
    assert net.tags.first.persisted?
    assert net.tags.first.name == 'Control Center'
    assert Tag.count == 1
  end
end
