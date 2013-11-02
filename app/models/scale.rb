class Scale < ActiveRecord::Base
  has_many :hoppers
  validates :name, presence: true
  validates :name, uniqueness: true
  validates :not_weighed, uniqueness: { if: :not_weighed }
  validates :maximum_weight, :minimum_weight, presence: { unless: :not_weighed }
  validates :minimum_weight, numericality: { greater_than_or_equal_to: 0, less_than: :maximum_weight, allow_nil: true }
  validates :maximum_weight, numericality: { greater_than: 0, allow_nil: true }

  def self.get_all
    scales = Scale.includes(:hoppers).order('not_weighed')
    hoppers_below_minimum = {}
    scales.each do |scale|
      hoppers_below_minimum[scale.id] = scale.hoppers.where(:stock_below_minimum => true).count
    end
    return scales, hoppers_below_minimum
  end
end
