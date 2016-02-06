class LotParameter < ActiveRecord::Base
  attr_protected :id

  belongs_to :lot_parameter_list
  belongs_to :lot_parameter_type

  validates :lot_parameter_list, :lot_parameter_type, presence: true
  validates :lot_parameter_type_id,
            uniqueness: {scope: :lot_parameter_list_id}
  validates :value, numericality: {allow_nil: true}
end
