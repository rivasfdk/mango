class Scale < ActiveRecord::Base
  has_many :hoppers
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_uniqueness_of :not_weighed, :if => :not_weighed
  validates_presence_of :maximum_weight, :minimum_weight, :unless => :not_weighed
  validates_numericality_of :minimum_weight, :greater_than_or_equal_to => 0, :less_than => :maximum_weight, :allow_nil => true
  validates_numericality_of :maximum_weight, :greater_than => 0, :allow_nil => true

  def self.get_all
    scales = Scale.includes(:hoppers).order('not_weighed')
    hoppers_below_minimum = {}
    scales.each do |scale|
      hoppers_below_minimum[scale.id] = scale.hoppers.where(:stock_below_minimum => true).count
    end
    return scales, hoppers_below_minimum
  end
end
