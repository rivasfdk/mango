class HopperFactoryLot < ActiveRecord::Base
  attr_accessible :lot_id
  belongs_to :hopper_lot
  belongs_to :client
  belongs_to :lot

  validates :hopper_lot, :client, presence: true
  validates :client_id, uniqueness: {scope: :hopper_lot_id}
  validate :factory_lot

  private

  def factory_lot
    if self.client.present?
      errors.add(:client, "no es una fábrica") unless self.client.factory
      if self.lot.present?
        errors.add(:lot, "no pertenece a la fábrica") unless self.client_id == self.lot.client_id
      end
    end
    if self.lot.present? and self.hopper_lot.present?
      errors.add(:lot, "no es del mismo ingrediente") unless self.hopper_lot.lot.ingredient_id == self.lot.ingredient_id
    end
  end
end
