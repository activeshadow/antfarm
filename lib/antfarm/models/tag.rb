module Antfarm
  module Models
    class Tag < ActiveRecord::Base
      belongs_to :taggable, :polymorphic => true
    end
  end
end
