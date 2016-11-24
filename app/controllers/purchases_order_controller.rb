class PurchasesOrderController < ApplicationController

  def get_all
    @purchasesorder = PurchaseOrder.where(closed: false)
    render json: @purchasesorder, methods: [:to_collection_select], root: false
  end
  
end
