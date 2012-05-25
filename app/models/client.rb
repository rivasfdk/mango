class Client < ActiveRecord::Base
  has_many :order
  has_many :transactions
  has_many :lots
  has_many :product_lots

  validates_uniqueness_of :ci_rif, :code
  validates_presence_of :name, :code, :ci_rif, :address, :tel1
  validates_length_of :ci_rif, :within => 3..10
  validates_length_of :name, :within => 3..40
  
  def to_collection_select
    return "#{self.name}"
  end
end
