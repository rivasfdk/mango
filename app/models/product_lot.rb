class ProductLot < ActiveRecord::Base
  include LotModule

  belongs_to :product
  belongs_to :client
  has_many :order

  validates_uniqueness_of :code
  validates_presence_of :date, :product
  validates_length_of :code, :within => 3..20

  def content_id
    self.product_id
  end

  def get_content
    Product.find self.product_id
  end

  def to_collection_select
    "#{self.product.name} (L: #{self.code})"
  end
end
