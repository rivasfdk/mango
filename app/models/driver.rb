class Driver < ActiveRecord::Base
  has_many :tickets

  validates_presence_of :name, :ci
  validates_length_of :ci, :within => 3..10
  validates_length_of :name, :within => 3..40
  
  def to_collection_select
    return "#{self.ci} - #{self.name}"
  end
end
