class HopperLotTransactionType < ActiveRecord::Base
  attr_protected :id

  has_many :hopper_lot_transactions

  validates_uniqueness_of :code
  validates_presence_of :code, :description, :sign
end
