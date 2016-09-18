# encoding: UTF-8

class BatchesHopperLotController < ApplicationController
  def create
    if not params[:batch_hopper_lot][:amount].blank? or not params[:batch_hopper_lot][:hopper_lot_id].blank?
      hopper_lot = HopperLot.find(params[:batch_hopper_lot][:hopper_lot_id])
      batch = Batch.find(params[:batch_id])
      hopper = Hopper.where(id: hopper_lot.hopper_id).first
      order = Order.where(id: batch.order_id).first

      if order.client.factory
        hfl = HopperFactoryLot.where(hopper_lot_id: hopper_lot.id, client_id: order.client_id).first
        if hfl.present? and hfl.lot_id.present?
          hopper_lot = hopper.hopper_lot.new
          hopper_lot.lot_id = hfl.lot_id
          hopper_lot.active = false
          hopper_lot.factory = true
          hopper_lot.save(validate: false)
        end
      end

      b = BatchHopperLot.new params[:batch_hopper_lot]
      b.batch = batch
      b.hopper_lot = hopper_lot
      if b.valid?
        b.save
        flash[:notice] = "Detalle agregado al batch"
      else
        logger.debug b.errors.inspect
        flash[:notice] = "No se pudo guardar el detalle"
        flash[:type] = 'error'
      end
    else
      flash[:notice] = "Por favor coloque datos válidos"
      flash[:type] = 'error'
    end
    redirect_to edit_batche_path(params[:batch_id])
  end

  def destroy
    @batch_hopper_lot = BatchHopperLot.find params[:id]
    @batch_hopper_lot.eliminate
    if @batch_hopper_lot.errors.empty?
      flash[:notice] = "Detalle de batch eliminado con éxito"
    else
      logger.error("Error eliminando detalle de batch: #{@batch_hopper_lot.errors.inspect}")
      flash[:type] = 'error'
      flash[:notice] = "No se pudo borrar el detalle de batch"
    end
    redirect_to edit_batche_path(params[:batch_id])
  end
end
