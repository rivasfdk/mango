class ProductParameterTypeRangesController < ApplicationController
def index
    @products = Product.paginate :page=>params[:page],
                                       :per_page=>session[:per_page],
                                       :order => ['id desc']
  end

  def show
    session[:return_to] = request.referer
    @product = Product.find params[:id], :include => {:product_parameter_type_ranges => {:product_lot_parameter_type => {}}}
  end

  def edit
    show
  end

  def update
    @product_parameter_type_range = ProductParameterTypeRange.find params[:id]
    @product_parameter_type_range.update_attributes(params[:product_parameter_type_range])
    if @product_parameter_type_range.save
      flash[:notice] = 'Rango actualizado con éxito'
    else
      flash[:type] = 'error'
      flash[:notice] = "No se pudo actualizar el rango"
    end
    redirect_to request.referer
  end

  def create
    product = Product.find params[:id]
    product.generate_parameter_type_ranges if product.product_parameter_type_ranges.empty?
    redirect_to edit_product_parameter_type_range_path product.id
  end

  def destroy
    @product = Product.find params[:id]
    @product.product_parameter_type_ranges.each do |pptr|
      pptr.destroy
    end
    redirect_to product_parameter_type_ranges_path
  end
end
