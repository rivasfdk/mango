class Lot < ActiveRecord::Base
  include LotModule

  belongs_to :ingredient
  belongs_to :client
  has_many :hopper_lot

  validates_uniqueness_of :code
  validates_presence_of :date, :ingredient_id
  validates_length_of :code, :within => 3..20
  validates_associated :ingredient

  def self.find_all
    find :all, :include => ['ingredient'], :order => 'code ASC'
  end
  
  def get_content
    Ingredient.find self.ingredient_id
  end

  def to_collection_select
   "#{self.ingredient.name} (L: #{self.code})"
  end
end
