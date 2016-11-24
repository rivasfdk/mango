class SalesOrderController < ApplicationController

  def get_all
    @salesorder = SaleOrder.where(closed: false)
    render json: @salesorder, methods: [:to_collection_select], root: false
  end

end
