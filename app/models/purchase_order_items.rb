class PurchaseOrderItems < ActiveRecord::Base
  attr_protected :id

  belongs_to :ingredient
end
