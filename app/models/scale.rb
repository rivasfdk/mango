class Scale < ActiveRecord::Base
  has_many :hoppers
  validates_presence_of :name, :maximum_weight, :minimum_weight
  validates_numericality_of :minimum_weight, :greater_than_or_equal_to => 0, :less_than => :maximum_weight
  validates_numericality_of :maximum_weight, :greater_than => 0
end
