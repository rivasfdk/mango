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
    if params["content_type"] == '1'
      @warehouse = Warehouse.where(lot_id: params["lot_id"], main: true)
    else
      @warehouse = Warehouse.where(product_lot_id: params["lot_id"], main: true)
    end
    if @warehouse.empty?
      sacks = WarehouseContents.find_by(content_id: params["lot_id"], content_type: params["content_type"])
      @warehouse = sacks.nil? ? [] : Warehouse.where(id: sacks.warehouse_id)
    end
    render json: @warehouse, methods: [:to_collection_select], root: false
  end

end
