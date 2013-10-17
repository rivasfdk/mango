class ProductLotParameter < ActiveRecord::Base
  belongs_to :product_lot_parameter_list
  belongs_to :product_lot_parameter_type

  validates_presence_of :product_lot_parameter_list, :product_lot_parameter_type
  validates_uniqueness_of :product_lot_parameter_type_id, :scope => :product_lot_parameter_list_id
  validates_numericality_of :value, :allow_nil => true

  def get_full_parameters(parameter_list_id)
    parameters = []
    parameter_list = ProductLotParameterList.find parameter_list_id, 
                     :include => {:product_lot_parameters => {:product_lot_parameter_type => {}}}
    .parameters.each do
    
    end
  end
end
