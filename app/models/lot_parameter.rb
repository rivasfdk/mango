class LotParameter < ActiveRecord::Base
  belongs_to :lot_parameter_list
  belongs_to :lot_parameter_type

  validates_presence_of :lot_parameter_list, :lot_parameter_type
  validates_uniqueness_of :lot_parameter_type_id, :scope => :lot_parameter_list_id
  validates_numericality_of :value, :allow_nil => true
end
