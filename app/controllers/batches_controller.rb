# encoding: UTF-8

class BatchesController < ApplicationController
  def index
    @batches = Batch.search(params)
  end

  def new
    fill
    @batch = Batch.new :user_id => session[:user_id]
    @user = User.find session[:user_id]
  end

  def edit
    fill
    @batch = Batch.find params[:id], :include=>{:batch_hopper_lot=>{:hopper_lot=>[{:lot=>:ingredient}, :hopper]}}, order: 'ingredients.code asc'
  end

  def create
    @batch = Batch.new params[:batch]
    @saved = @batch.save
    if @saved
      flash[:notice] = 'Batch guardado con éxito'
      redirect_to :batches
    else
      fill
      render :new
    end
  end

  def update
    @batch = Batch.find params[:id]
    @batch.update_attributes(params[:batch])
    if @batch.save
      flash[:notice] = 'Batch actualizado con éxito'
      redirect_to :batches
    else
      fill
      render :edit
    end
  end

  def destroy
    @batch = Batch.find params[:id]
    @batch.eliminate
    if @batch.errors.empty?
      flash[:notice] = 'Batch eliminado con éxito'
    else
      logger.error("Error eliminando batch: #{@batch.errors.inspect}")
      flash[:type] = 'error'
      if not @batch.errors[:foreign_key].nil?
        flash[:notice] = 'El batch no se puede eliminar porque tiene registros asociados'
      elsif not @batch.errors[:unknown].nil?
        flash[:notice] = @batch.errors[:unknown]
      else
        flash[:notice] = "El batch no se ha podido eliminar"
      end
    end
    redirect_to :batches
  end

  private

  def fill
    @orders = Order.where(['completed = ?', false])
    @users = User.order('name ASC')
    @schedules = Schedule.order('name ASC')
    @hoppers = Hopper.actives_to_select
    @user = User.find session[:user_id]
  end
end
