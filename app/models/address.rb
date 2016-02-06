class Address < ActiveRecord::Base
  attr_protected :id

  belongs_to :client
end
