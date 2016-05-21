class DisplayUnit < ActiveRecord::Base
  attr_protected :id

  belongs_to :base_unit
end
