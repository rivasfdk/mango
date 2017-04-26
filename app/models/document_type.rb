class DocumentType < ActiveRecord::Base
  attr_protected :id

  has_many :tickets
  has_many :sale_order
end
