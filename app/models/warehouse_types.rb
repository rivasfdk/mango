class WarehouseTypes < ActiveRecord::Base
 attr_protected :id

  has_many :warehouses

  validates :name, presence: true
  validates :name, length: {within: 3..40}

  def self.search(params)
    @warehouse_types = WarehouseTypes.order('warehouses_types.id DESC')
    #@warehouse_types = @warehouse_types.includes(:name)  # Add the other ones
    @warehouse_types = @warehouse_types.where('orders.name = ?', params[:order_name]) if params[:order_name].present?
    @warehouse_types.paginate page: params[:page], per_page: params[:per_page]
  end
 
end
