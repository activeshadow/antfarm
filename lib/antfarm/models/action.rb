module Antfarm
  module Models
    class Action < ActiveRecord::Base
      has_many :os
      has_many :services
    end
  end
end
