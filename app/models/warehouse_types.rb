class WarehouseTypes < ActiveRecord::Base
 attr_protected :id

  has_many :warehouses

  validates :name, :code, presence: true
  validates :name, length: {within: 3..40}
  validates :content_type, inclusion: [true, false]

  def self.search(params)
    @warehouse_types = WarehouseTypes.order('warehouses_types.id ASC')
    @warehouse_types.paginate page: params[:page], per_page: params[:per_page]
  end

  def self.get_warehouses_products
    warehouses_types = WarehouseTypes.all
      .pluck(:id, :name, :code)
      .map do |warehouse_type|
        {id: warehouse_type[0], name: warehouse_type[1], code: warehouse_type[2]}
      end
    warehouses_types.each do |warehouse_type|
      warehouse_type[:warehouses] = Warehouse.where(warehouse_types_id: warehouse_type[:id]) 
        .pluck('code', 'name', 'lot_id', 'product_lot_id')
        .map do |warehouse|
          product = warehouse[2].nil? ? ProductLot.find(warehouse[3]).product : Lot.find(warehouse[2]).ingredient
          {code: warehouse[0], name: warehouse[1],  product_code: product.code, product_name: product.name}
        end
    end
    warehouses_types
  end
 
end
