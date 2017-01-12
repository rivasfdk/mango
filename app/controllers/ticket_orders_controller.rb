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

  def get_order_data
    @order_data = TicketOrder.find(params["id_order"])
    @client = Client.find(@order_data.client_id)
    #binding.pry
    render json: @client, methods: [:to_collection_select], root: false
  end

end
