  # encoding: UTF-8

include MangoModule

class TicketOrdersController < ApplicationController

  def get_all_reception
    @rorders = TicketOrder.where(order_type: true, closed: false)
    render json: @rorders, methods: [:to_collection_select], root: false
  end

  def get_all_dispatch
    @dorders = TicketOrder.where(order_type: false, closed: false)
    render json: @dorders, methods: [:to_collection_select], root: false
  end

  def get_order_client
    @order = TicketOrder.includes(client: {}).find params["id_order"], :include => :ticket_orders_items
    render json: @order.client, methods: [:to_collection_select], root: false
  end

  def get_item_warehouse
    @warehouse = Warehouse.where(content_id: params["lot_id"], content_type: params["content_type"])
    if @warehouse.empty?
      warehouse_id = (WarehouseContents.find_by(content_id: params["lot_id"], content_type: params["content_type"])).warehouse_id
      @warehouse = Warehouse.where(id: warehouse_id)
    end
    render json: @warehouse, methods: [:to_collection_select], root: false
  end

end
