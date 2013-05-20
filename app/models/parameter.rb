class Parameter < ActiveRecord::Base
  belongs_to :parameter_list
  belongs_to :parameter_type

  validates_presence_of :value, :parameter_list, :parameter_type
  validates_uniqueness_of :parameter_type_id, :scope => :parameter_list_id
  validates_numericality_of :value
end
