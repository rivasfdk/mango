class Client < ActiveRecord::Base
  has_many :order, inverse_of: :client
  has_many :transactions
  has_many :tickets
  has_many :lots
  has_many :product_lots
  has_many :hopper_factory_lots

  validates :ci_rif, uniqueness: true
  validates :code, uniqueness: {scope: :factory}
  validates :name, :code, :ci_rif, :address, :tel1, presence: true
  validates :ci_rif, length: {within: 3..15}
  validates :name, length: {within: 3..40}

  after_create :generate_factory_lots, if: :factory

  def generate_factory_lots
    hopper_lots = HopperLot.includes(:hopper_factory_lots).where(['active = true and hoppers_factory_lots_count > 0'])
    hopper_lots.each do |hl|
      hopper_factory_lot = hl.hoppers_factory_lots.new
      hopper_factory_lot.client_id = self.id
      hopper_factory_lot.save
    end
  end

  def to_collection_select
    client_type = self.factory ? "(F)" : "(C)"
    return "#{self.name} #{client_type}"
  end
end
