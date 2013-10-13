class Lot < ActiveRecord::Base
  include LotModule

  belongs_to :ingredient
  belongs_to :client
  has_many :hopper_lot
  has_one :lot_parameter_list

  before_save :check_stock

  validates_uniqueness_of :code
  validates_presence_of :date, :ingredient
  validates_length_of :code, :within => 3..20
  validates_associated :ingredient

  def check_stock
    self.stock_below_minimal = self.stock < self.minimal_stock
    true
  end

  def self.find_all
    includes(:ingredient).where(:active => true).order('code DESC')
  end

  def get_content
    Ingredient.find self.ingredient_id
  end

  def to_collection_select
    "#{self.ingredient.code} - #{self.ingredient.name} (L: #{self.code})"
  end
end
