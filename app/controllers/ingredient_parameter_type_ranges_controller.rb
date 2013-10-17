class IngredientParameterTypeRangesController < ApplicationController
  def index
    @ingredients = Ingredient.paginate :page=>params[:page],
                                       :per_page=>session[:per_page],
                                       :order => ['id desc']
  end

  def show
    session[:return_to] = request.referer
    @ingredient = Ingredient.find params[:id], :include => {:ingredient_parameter_type_ranges => {:lot_parameter_type => {}}}
  end

  def edit
    show
  end

  def update
    @ingredient_parameter_type_range = IngredientParameterTypeRange.find params[:id]
    @ingredient_parameter_type_range.update_attributes(params[:ingredient_parameter_type_range])
    if @ingredient_parameter_type_range.save
      flash[:notice] = 'Rango actualizado con éxito'
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo actualizar el rango"
    end
    redirect_to request.referer
  end

  def create
    @ingredient = Ingredient.find params[:id]
    @ingredient.generate_parameter_type_ranges if @ingredient.ingredient_parameter_type_ranges.empty?
    redirect_to edit_ingredient_parameter_type_range_path @ingredient.id
  end

  def destroy
    @ingredient = Ingredient.find params[:id]
    @ingredient.ingredient_parameter_type_ranges.each do |iptr|
      iptr.destroy
    end
    redirect_to ingredient_parameter_type_ranges_path
  end
end
