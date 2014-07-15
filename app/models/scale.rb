class Scale < ActiveRecord::Base
  has_many :hoppers
  validates :name, presence: true
  validates :name, uniqueness: true
  validates :not_weighed, uniqueness: { if: :not_weighed }
  validates :maximum_weight, :minimum_weight, presence: { unless: :not_weighed }
  validates :minimum_weight, numericality: { greater_than_or_equal_to: 0, less_than: :maximum_weight, allow_nil: true }
  validates :maximum_weight, numericality: { greater_than: 0, allow_nil: true }

  def self.get_all
    scales = Scale.order('not_weighed')
    hoppers_below_minimum = Hopper
      .select("scale_id,
               SUM(stock_below_minimum) AS below_minimum_count")
      .group("scale_id")
      .reduce(Hash.new { |h,k| h[k] = 0 }) do |hash, hopper|
        hash[hopper[:scale_id]] = hopper[:below_minimum_count]
        hash
      end
    return scales, hoppers_below_minimum
  end
end
