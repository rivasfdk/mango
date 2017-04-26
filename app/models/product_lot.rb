class ProductLot < ActiveRecord::Base
  include LotModule

  attr_protected :stock

  belongs_to :product
  belongs_to :client
  has_many :orders

  has_one :product_lot_parameter_list

  validates :code, presence: true,
                   uniqueness: true,
                   length: {within: 3..20}
  validates :product_id, presence: true

  def content_id
    self.product_id
  end

  def get_content
    self.product
  end

  def to_collection_select
    "#{self.product.name} (L: #{self.code})"
  end

  def self.search(params)
    product_lots = ProductLot.includes(:product).where(active: true, empty: nil)
    product_lots = product_lots.where(product_id: params[:product_id]) if params[:product_id].present?
    product_lots = product_lots.where(client_id: params[:client_id].to_i > 0 ? params[:client_id] : nil) if params[:client_id].present?
    product_lots = product_lots.order('id desc')
    product_lots.paginate page: params[:page], per_page: params[:per_page]
  end
end
