class MixingTime < ActiveRecord::Base
  has_many :recipes
  
  validates_presence_of :code, :wet_time, :dry_time
  validates_numericality_of :wet_time, :dry_time, :greater_than => 0
  validates_uniqueness_of :code
end
