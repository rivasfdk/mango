class BaseUnit < ActiveRecord::Base
  attr_protected :id

  has_many :product
  has_many :ingredient
  has_many :display_unit
end
