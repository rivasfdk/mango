class Lot < ActiveRecord::Base
  include LotModule

  belongs_to :ingredient
  belongs_to :client
  has_many :hopper_lot
  has_many :hopper_factory_lots
  has_one :lot_parameter_list

  after_save :check_stock, :check_hopper_stock

  validates_uniqueness_of :code
  validates_presence_of :date, :ingredient
  validates_length_of :code, :within => 3..20
  validates_associated :ingredient
  validate :factory

  def factory
    errors.add(:client, "no es fábrica") if self.client.present? and not self.client.factory
  end

  def check_stock
    ingredient = Ingredient.find self.ingredient_id
    ingredient.save
    true
  end

  def check_hopper_stock
    hoppers = Hopper.includes(:hopper_lot).where(['hoppers_lots.active = true and hoppers_lots.lot_id = ?', self.id])
    hoppers.each do |hopper|
      hopper.save
    end
  end

  def self.find_all
    includes(:ingredient).where(:active => true).order('code DESC')
  end

  def self.find_by_factory(lot)
    lots_by_factory = {}
    Client.where(:factory => true).each do |client|
      lots_by_factory[client.id] = []
    end
    lots = Lot.includes(:ingredient).where(:active => true, :in_use => true).where(['client_id is not null and ingredient_id = ?', lot.ingredient_id])
    lots.each do |lot|
      lots_by_factory[lot.client_id] << lot
    end
    lots_by_factory
  end

  def content_id
    self.ingredient_id
  end

  def get_content
    Ingredient.find self.ingredient_id
  end

  def to_collection_select
    "#{self.ingredient.code} - #{self.ingredient.name} (L: #{self.code})"
  end
end
