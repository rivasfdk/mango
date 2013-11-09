class OrderArea < ActiveRecord::Base
  belongs_to :area
  belongs_to :order

  validates :order_id, :area_id, presence: true

  before_save :update_actives, if: :new_record?

  def update_actives
    OrderArea.where(order_id: self.order_id).update_all(active: false)
    self.active = true
  end
end
