class OrderArea < ActiveRecord::Base
  attr_protected :id

  belongs_to :area
  belongs_to :order

  validates :order, :area, presence: true

  before_save :update_actives, if: :new_record?

  def update_actives
    OrderArea.where(area_id: self.area_id).update_all(active: false)
    self.active = true
  end
end
