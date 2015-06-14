class DocumentType < ActiveRecord::Base
  has_many :tickets
end
