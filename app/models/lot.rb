class Lot < ActiveRecord::Base
  include LotModule

  attr_protected :stock

  belongs_to :ingredient
  belongs_to :client
  has_many :hopper_lot
  has_many :hopper_factory_lots
  has_one :lot_parameter_list

  after_save :check_stock, :check_hopper_stock

  validates :code, presence: true,
                   uniqueness: true,
                   length: {within: 3..20}
  validates :ingredient, presence: true
  validates :density, numericality: {greater_than: 0}
  validate :factory

  def factory
    if self.client.present? and not self.client.factory
      errors.add(:client, "no es fábrica")
    end
  end

  def check_stock
    Ingredient.find(self.ingredient_id)
              .save
    true
  end

  def check_hopper_stock
    Hopper.includes(:hopper_lot)
          .where({hoppers_lots: {active: true,
                                 lot_id: self.id}})
          .each { |hopper| hopper.save }
  end

  def self.find_all
    Lot.includes(:ingredient)
       .where(active: true)
       .order('code DESC')
  end

  def self.find_by_factory(lot)
    lots_by_factory = {}
    Client.where(factory: true)
          .each {|client| lots_by_factory[client.id] = []}
    lots = Lot.includes(:ingredient)
              .where(active: true, in_use: true)
              .where(['client_id is not null and ingredient_id = ?', lot.ingredient_id])
    lots.each {|lot| lots_by_factory[lot.client_id] << lot}
    lots_by_factory
  end

  def content_id
    self.ingredient_id
  end

  def get_content
    self.ingredient
  end

  def to_collection_select
    "#{self.ingredient.code} - #{self.ingredient.name} (L: #{self.code})"
  end

  def self.search(params)
    lots = Lot.includes(:ingredient).where(active: true)
    lots = lots.where(ingredient_id: params[:ingredient_id]) if params[:ingredient_id].present?
    lots = lots.order('id desc')
    lots.paginate page: params[:page], per_page: params[:per_page]
  end
end
