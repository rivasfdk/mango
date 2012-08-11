class Lot < ActiveRecord::Base
  belongs_to :ingredient
  belongs_to :client
  has_many :hopper_lot

  validates_uniqueness_of :code
  validates_presence_of :date, :ingredient_id
  validates_length_of :code, :within => 3..20
  validates_associated :ingredient
  
  #after_save :set_unused

  #def set_unused
  #  lots = Lot.find :all, :conditions => ['ingredient_id = ? and id != ?', self.ingredient_id, self.id]
  #  lots.each do |lot|
  #    lot.in_use = false
  #    lot.save
  #  end
  #end

  def self.find_all
    find :all, :include => ['ingredient'], :order => 'code ASC'
  end

  def to_collection_select
   "#{self.ingredient.name} (L: #{self.code})"
  end
end
