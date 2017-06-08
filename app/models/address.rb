class Address < ActiveRecord::Base
  attr_protected :id

  belongs_to :client

  def to_collection_select
    "#{self.address}"
  end

end
