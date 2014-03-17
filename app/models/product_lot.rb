class ProductLot < ActiveRecord::Base
  include LotModule

  attr_protected

  belongs_to :product
  belongs_to :client
  has_many :order

  has_one :product_lot_parameter_list

  validates :code, presence: true,
                   uniqueness: true,
                   length: {within: 3..20}
  validates :product, presence: true

  def content_id
    self.product_id
  end

  def get_content
    self.product
  end

  def to_collection_select
    "#{self.product.name} (L: #{self.code})"
  end
end
