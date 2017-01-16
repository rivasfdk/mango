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
    @items = TicketOrderItems.where(ticket_order_id: params["id_order"])
    @items.each do |item|
      if item.content_type
        content_id = (Lot.find_by id: item.content_id).ingredient_id
      else
        content_id = (ProductLot.find_by id: item.content_id).product_id
      end
      @warehouse = Warehouse.where(content_id: content_id, content_type: item.content_type)
    end
    render json: @warehouse, methods: [:to_collection_select], root: false
  end

end
