require 'test_helper'

class EthIfTest < TestCase
  include Antfarm::Models

  test 'fails with no address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ethiface, :address => nil
    end

    assert !Fabricate.build(:ethiface, :address => nil).valid?
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ethiface, :address => '00:00:00:00:00:0Z'
    end

    assert !Fabricate.build(:ethiface, :address => '00:00:00:00:00:0Z').valid?
  end
end
