class Client < ActiveRecord::Base
  has_many :order, inverse_of: :client
  has_many :transactions
  has_many :tickets
  has_many :lots
  has_many :product_lots
  has_many :hopper_factory_lots, dependent: :destroy
  has_many :addresses, dependent: :destroy

  accepts_nested_attributes_for :addresses, allow_destroy: true, reject_if: lambda { |a| a[:address].blank? }

  validates :ci_rif, uniqueness: true
  validates :code, uniqueness: {scope: :factory}
  validates :name, :code, :ci_rif, :address, :tel1, presence: true
  validates :ci_rif, length: {within: 3..15}
  validates :name, length: {within: 3..40}

  after_create :generate_factory_lots, if: :factory

  def generate_factory_lots
    hopper_lots = HopperLot.includes(:hoppers_factory_lots).where(active: true)
    hopper_lots.each do |hl|
      if hl.hoppers_factory_lots.count > 0
        hopper_factory_lot = hl.hoppers_factory_lots.new
        hopper_factory_lot.client_id = self.id
        hopper_factory_lot.save
      end
    end
  end

  def to_collection_select
    client_type = self.factory ? "(M)" : "(C)"
    return "#{self.name} #{client_type}"
  end

  def self.get_all()
    # Proporca
    #Client.where(factory: true).unshift Client.where(id: 980190963).first
    Client.all
  end
end
