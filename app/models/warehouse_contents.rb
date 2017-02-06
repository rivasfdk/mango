class WarehouseContents < ActiveRecord::Base
  attr_protected :id

  belongs_to :warehouse

  def get_lot
    if self.content_type
      Lot.find self.content_id
    else
      ProductLot.find self.content_id
    end
  end

end
