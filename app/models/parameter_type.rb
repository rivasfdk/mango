class ParameterType < ActiveRecord::Base
  belongs_to :parameters

  validates_presence_of :name
  validates_uniqueness_of :name
end
