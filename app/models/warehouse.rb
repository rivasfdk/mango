class Warehouse < ActiveRecord::Base
  attr_protected :id

  belongs_to :ingredient
  has_many :warehouse_types

  validates :name, :code, presence: true
  validates :code, uniqueness: true
  validates :code, :name, length: {within: 3..40}
  validates :stock, numericality: {greater_than_or_equal_to: 0}


  def self.search(params)
    @warehouses = Warehouse.order('warehouses.id DESC')
    @warehouses = @warehouses.includes(:ingredient)  # Add the other ones.
    @warehouses = @warehouses.where('orders.code = ?', params[:order_code]) if params[:order_code].present?
    @warehouses.paginate page: params[:page], per_page: params[:per_page]
  end

end


  