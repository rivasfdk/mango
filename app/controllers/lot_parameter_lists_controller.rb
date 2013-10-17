class LotParameterListsController < ApplicationController
  def index
    @lots = Lot.paginate :page=>params[:page],
                         :per_page=>session[:per_page],
                         :include => :ingredient, 
                         :conditions => {:active => true},
                         :order => ['id desc']
  end

  def show
    @lot_parameter_list = LotParameterList.find params[:id],
                                                :include => {:lot_parameters => {:lot_parameter_type => {}},
                                                :lot => {:ingredient => {}}}
    @parameters = @lot_parameter_list.parameters_with_range
    session[:return_to] = request.referer
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
      logger.error("Error eliminando características de lote: #{@lot_parameter_list.errors.inspect}")
      flash[:type] = 'error'
      if not @lot_parameter_list.errors[:foreign_key].nil?
        flash[:notice] = 'No se pueden eliminar las características del lote porque tiene registros asociados'
      elsif not @lot_parameter_list.errors[:unknown].nil?
        flash[:notice] = @lot_parameter_list.errors[:unknown]
      else
        flash[:notice] = "Las características del lote no se han podido eliminar"
      end
    end
  end  
end
