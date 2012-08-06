class Carrier < ActiveRecord::Base
  has_many :trucks

  validates_presence_of :code, :name
  #validates_uniqueness_of :code
  validates_length_of :name, :within => 3..40

end
