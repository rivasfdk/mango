class ProductParameterTypeRangesController < ApplicationController
def index
    @products = Product.paginate :page=>params[:page],
                                       :per_page=>session[:per_page],
                                       :order => ['id desc']
  end

  def show
    @product = Product.find params[:id], :include => {:product_parameter_type_ranges => {:product_lot_parameter_type => {}}}
    session[:return_to] = request.referer
  end

  def edit
    show
  end

  def update
    @product = Product.find params[:id]
    @product.update_attributes(params[:product])
    if @product.save
      flash[:notice] = 'Rangos actualizados con éxito'
      redirect_to session[:return_to]
    else
      render :edit
    end
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
