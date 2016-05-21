class DocumentType < ActiveRecord::Base
  attr_protected :id

  has_many :tickets
end
