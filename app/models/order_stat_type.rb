class OrderStatType < ActiveRecord::Base
  attr_protected :id

  belongs_to :area
  has_many :order_stats

  validates :max, numericality: {allow_nil: true}
  validates :min, numericality: {less_than_or_equal_to: :max, allow_nil: true}
  validates :code, :description, presence: true
  validates :code, uniqueness: true
  validate :unit_is_defined

  UNITS = {"s" => "Tiempo (segundos)", "degC" => "Temperatura (°C)"}

  def unit_is_defined
    errors.add(:unit, " es inválida") if self.unit.present? and not UNITS.keys.include? self.unit
  end
end
