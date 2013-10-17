class IngredientParameterTypeRangesController < ApplicationController
  def index
    @ingredients = Ingredient.paginate :page=>params[:page],
                                       :per_page=>session[:per_page],
                                       :order => ['id desc']
  end

  def show
    @ingredient = Ingredient.find params[:id], :include => {:ingredient_parameter_type_ranges => {:lot_parameter_type => {}}}
    session[:return_to] = request.referer
  end

  def edit
    show
  end

  def update
    @ingredient = Ingredient.find params[:id]
    @ingredient.update_attributes(params[:ingredient])
    if @ingredient.save
      flash[:notice] = 'Rangos actualizados con éxito'
      redirect_to session[:return_to]
    else
      render :edit
    end
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
