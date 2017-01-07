class PurchasesOrderController < ApplicationController

  def get_all
    @purchasesorder = PurchaseOrder.where(closed: false)
    render json: @purchasesorder, methods: [:to_collection_select], root: false
  end

  def get_order_data
    @order_data = PurchaseOrder.find(params["id_order"])
    @client = Client.find(@order_data.id_client)
    #binding.pry
    render json: @client, methods: [:to_collection_select], root: false
  end
end
