class LotParameterListsController < ApplicationController
  def index
    @lots = Lot.paginate :page=>params[:page],
                         :per_page=>session[:per_page],
                         :include => :ingredient, 
                         :conditions => {:active => true}
  end

  def show
    @lot_parameter_list = LotParameterList.find params[:id],
                                                :include => {:lot_parameters => {:lot_parameter_type => {}},
                                                :lot => {:ingredient => {}}}
  end

  def edit
    show
  end

  def create
    @lot = Lot.find params[:lot_id]
    if @lot.lot_parameter_list.nil?
      @lot_parameter_list = LotParameterList.new
      @lot_parameter_list.lot_id = @lot.id
      @lot_parameter_list.save
      redirect_to edit_lot_parameter_list_path(@lot_parameter_list)
    else
      redirect_to edit_lot_parameter_list_path @lot.lot_parameter_list
    end
  end
  
  def destroy
    @lot_parameter_list = LotParameterList.find params[:id]
    @lot_parameter_list.eliminate
    if @lot_parameter_list.errors.size.zero?
      flash[:notice] = "Características de lote eliminado con éxito"
    else
      logger.error("Error eliminando lote: #{@lot_parameter_list.errors.inspect}")
      flash[:type] = 'error'
      if not @lot_parameter_list.errors[:foreign_key].nil?
        flash[:notice] = 'El lote no se puede eliminar porque tiene registros asociados'
      elsif not @lot_parameter_list.errors[:unknown].nil?
        flash[:notice] = @lot.errors[:unknown]
      else
        flash[:notice] = "El lote no se ha podido eliminar"
      end
    end
  end  
end
