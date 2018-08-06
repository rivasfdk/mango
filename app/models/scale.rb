class Scale < ActiveRecord::Base
  attr_protected :id

  has_many :hoppers
  validates :name, presence: true
  validates :name, uniqueness: true
  #validate :not_weighed_uniqueness
  validates :maximum_weight, :minimum_weight, presence: { unless: :not_weighed }
  validates :minimum_weight, numericality: { greater_than_or_equal_to: 0, less_than: :maximum_weight, allow_nil: true }
  validates :maximum_weight, numericality: { greater_than: 0, allow_nil: true }

  #def not_weighed_uniqueness
  #  errors.add(:not_weighed, :taken) if not_weighed && Scale.where(not_weighed: true).any?
  #end

  def self.get_all
    scales = Scale.order('id')
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

  def self.get_hoppers_ingredients
    scales = Scale.all
      .pluck(:id, :name, :minimum_weight, :maximum_weight)
      .map do |scale|
        {id: scale[0], name: scale[1], minimum_weight: scale[2], maximum_weight: scale[3]}
      end
    scales.each do |scale|
      scale[:hoppers] = HopperLot.includes({lot: {ingredient: {}}, hopper: {scale: {}}})
        .where(active: true)
        .where(hoppers: {scale_id: scale[:id]})
        .pluck('hoppers.number', 'hoppers.name AS hopper_name', 'hoppers.priority AS hopper_priority', 
               'ingredients.name AS ingredient_name', 'ingredients.code AS ingredient_code',
               'hoppers_lots.stock AS hopper_stock', 'hoppers.id')
        .map do |hopper|
          capacity = Hopper.find(hopper[6]).capacity_in_kg
          {number: hopper[0], name: hopper[1], hopper_priority: hopper[2], ingredient_name: hopper[3],
           ingredient_code: hopper[4], hopper_stock: hopper[5], hopper_capacity: capacity}
        end
    end

    scales
  end
end


