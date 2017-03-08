class WarehouseTransactions < ActiveRecord::Base
  attr_protected :id

  belongs_to :transaction_type
  belongs_to :warehouse
  belongs_to :user
  belongs_to :ticket

  validates :transaction_type_id, :warehouse_id, :amount, :lot_id, :user_id, presence: true
  validates :amount, numericality: true

end
