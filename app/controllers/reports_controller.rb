# encoding: UTF-8

class ReportsController < ApplicationController

  def index
    @drivers = Driver.find :all, :conditions => ['frequent = true']
    @carriers = Carrier.find :all, :conditions => ['frequent = true']
    @clients = Client.find :all
    @factories = Client.where :factory => true
    @alarm_types = AlarmType.find :all
  end

  def daily_production
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.daily_production(start_date, end_date)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'daily_production.yml'
      send_data report.render, :filename => "produccion_diaria.pdf", :type => "application/pdf"
    end
  end

  def real_production
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.real_production(start_date, end_date)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'real_production.yml'
      send_data report.render, :filename => "produccion_fisico.pdf", :type => "application/pdf"
    end
  end

  def order_duration
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.order_duration(start_date, end_date)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'order_duration.yml'
      send_data report.render, :filename => "duracion_de_orden_produccion.pdf", :type => "application/pdf"
    end
  end

  def order_details
    data = EasyModel.order_details(params[:report][:order])
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'order_details.yml'
      send_data report.render, :filename => "detalle_orden_produccion.pdf", :type => "application/pdf"
    end
  end

  def order_details_real
    data = EasyModel.order_details_real(params[:report][:order])
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'order_details_real.yml'
      send_data report.render, :filename => "detalle_orden_produccion_fisico.pdf", :type => "application/pdf"
    end
  end

  def batch_details
    data = EasyModel.batch_details(params[:report][:order], params[:report][:batch])
    puts data.inspect
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'batch_details.yml'
      send_data report.render, :filename => "detalle_batch.pdf", :type => "application/pdf"
    end
  end

  def consumption_per_recipe
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.consumption_per_recipe(start_date, end_date, params[:report][:recipe], params[:report][:version])
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'consumption_per_recipe.yml'
      send_data report.render, :filename => "consumo_por_receta.pdf", :type => "application/pdf"
    end
  end

  def consumption_per_selected_ingredients
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    ingredients_codes = params[:report]['ingredients_codes'].delete(" ").split(",")
    data = EasyModel.consumption_per_selected_ingredients(start_date, end_date, ingredients_codes)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'consumption_per_ingredients.yml'
      send_data report.render, :filename => "consumo_por_ingredientes.pdf", :type => "application/pdf"
    end
  end
  
  def consumption_per_ingredient_per_orders
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    ingredient_code = params[:report]['ingredient_code']
    data = EasyModel.consumption_per_ingredient_per_orders(start_date, end_date, ingredient_code)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'consumption_per_ingredient_per_orders.yml'
      send_data report.render, :filename => "consumo_por_ingrediente_por_ordenes.pdf", :type => "application/pdf"
    end
  end

  def consumption_per_ingredients
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.consumption_per_ingredients(start_date, end_date)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'consumption_per_ingredients.yml'
      send_data report.render, :filename => "consumo_por_ingredientes.pdf", :type => "application/pdf"
    end
  end

  def consumption_per_client
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.consumption_per_client(start_date, end_date, params[:report][:client_id])
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'consumption_per_client.yml'
      send_data report.render, :filename => "consumo_por_cliente.pdf", :type => "application/pdf"
    end
  end

  def stock_adjustments
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')

    data = EasyModel.stock_adjustments(start_date, end_date)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'stock_adjustments.yml'
      send_data report.render, :filename => "ajustes_de_inventario.pdf", :type => "application/pdf"
    end
  end

  def lots_incomes
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.lots_incomes(start_date, end_date)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'lots_incomes.yml'
      send_data report.render, :filename => "entrada_materia_prima.pdf", :type => "application/pdf"
    end
  end

  def simple_stock
    content_type = params[:report][:content_type].to_i
    date = EasyModel.param_to_date(params[:report], 'date')
	by_factory = params[:report][:by_factory].to_i
    if by_factory != 0
      factory_id = params[:report][:factory_id].to_i
    else
      factory_id = 0
    end
    if params[:report][:group] == '1'
      data = EasyModel.simple_stock(content_type, factory_id, date)
    else
      data = EasyModel.simple_stock_per_lot(content_type, factory_id, date)
    end
    if data.nil?
      flash[:notice] = 'No hay registros para general el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      filename = (content_type == 1) ? "inventario_materia_prima.pdf" : "inventario_producto_terminado.pdf"
      report = EasyReport::Report.new data, 'simple_stock.yml'
      send_data report.render, :filename => filename, :type => "application/pdf"
    end   
  end

  def simple_stock_projection
	by_factory = params[:report][:by_factory].to_i
	days = params[:report][:days]
    if by_factory != 0
      factory_id = params[:report][:factory_id].to_i
    else
      factory_id = 0
    end
    data = EasyModel.simple_stock_projection(factory_id, days)
    if data.nil?
      flash[:notice] = 'No hay registros para general el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      filename = "proyeccion_materia_prima.pdf"
      report = EasyReport::Report.new data, 'simple_stock_projection.yml'
      send_data report.render, :filename => filename, :type => "application/pdf"
    end   
  end

  def product_lots_dispatches
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.product_lots_dispatches(start_date, end_date, params[:report][:doc_number])
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'product_lots_dispatches.yml'
      send_data report.render, :filename => "despachos_producto_terminado.pdf", :type => "application/pdf"
    end
  end

  def production_per_recipe
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.production_per_recipe(start_date, end_date, params[:report][:recipe], params[:report][:version])
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'production_per_recipe.yml'
      send_data report.render, :filename => "produccion_por_receta.pdf", :type => "application/pdf"
    end
  end

  def production_per_client
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.production_per_client(start_date, end_date, params[:report][:client_id2])
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'production_per_client.yml'
      send_data report.render, :filename => "produccion_por_cliente.pdf", :type => "application/pdf"
    end
  end
  
  def tickets_transactions
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    ticket_type_id = params[:report][:ticket_type_id].to_i
    warehouse_type_id = params[:report][:warehouse_type_id].to_i
    data = EasyModel.tickets_transactions(start_date, end_date, ticket_type_id, warehouse_type_id)
    
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      template = (warehouse_type_id == 1) ? 'tickets_transactions_ingredients.yml' : 'tickets_transactions_products.yml'
      filename = (warehouse_type_id == 1) ? 'movimientos_materia_prima.pdf' : 'movimientos_producto_terminado.pdf'
      report = EasyReport::Report.new data, template
      send_data report.render, :filename => filename, :type => "application/pdf"
    end
  end

  def tickets_transactions_per_clients
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    ticket_type_id = params[:report][:ticket_type_id].to_i
    warehouse_type_id = params[:report][:warehouse_type_id].to_i
    clients_codes = params[:report][:clients_codes].delete(" ").split(",")
    data = EasyModel.tickets_transactions_per_clients(start_date, end_date, ticket_type_id, warehouse_type_id, clients_codes)
    
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      template = (warehouse_type_id == 1) ? 'tickets_transactions_ingredients.yml' : 'tickets_transactions_products.yml'
      filename = (warehouse_type_id == 1) ? 'movimientos_materia_prima_por_proveedor.pdf' : 'movimientos_producto_terminado_por_cliente.pdf'
      report = EasyReport::Report.new data, template
      send_data report.render, :filename => filename, :type => "application/pdf"
    end
  end

  def tickets_transactions_per_contents
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    ticket_type_id = params[:report][:ticket_type_id].to_i
    warehouse_type_id = params[:report][:warehouse_type_id].to_i
    contents_codes = params[:report][:contents_codes].delete(" ").split(",")
    data = EasyModel.tickets_transactions_per_contents(start_date, end_date, ticket_type_id, warehouse_type_id, contents_codes)
    
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      template = (warehouse_type_id == 1) ? 'tickets_transactions_ingredients.yml' : 'tickets_transactions_products.yml'
      filename = (warehouse_type_id == 1) ? 'movimientos_materia_prima_por_mp.pdf' : 'movimientos_producto_terminado_por_pt.pdf'
      report = EasyReport::Report.new data, template
      send_data report.render, :filename => filename, :type => "application/pdf"
    end
  end

  def tickets_transactions_per_contents_per_clients
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    ticket_type_id = params[:report][:ticket_type_id].to_i
    warehouse_type_id = params[:report][:warehouse_type_id].to_i
    contents_codes = params[:report][:contents_codes].delete(" ").split(",")
    clients_codes = params[:report][:clients_codes].delete(" ").split(",")
    data = EasyModel.tickets_transactions_per_contents_per_clients(start_date, end_date, ticket_type_id, warehouse_type_id, contents_codes, clients_codes)

    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      template = (warehouse_type_id == 1) ? 'tickets_transactions_ingredients.yml' : 'tickets_transactions_products.yml'
      filename = (warehouse_type_id == 1) ? 'movimientos_materia_prima_por_mp_por_proveedor.pdf' : 'movimientos_producto_terminado_por_pt_por_cliente.pdf'
      report = EasyReport::Report.new data, template
      send_data report.render, :filename => filename, :type => "application/pdf"
    end
  end

  def tickets_transactions_per_carrier
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    ticket_type_id = params[:report][:ticket_type_id].to_i
    warehouse_type_id = params[:report][:warehouse_type_id].to_i
    carrier_id = params[:report][:carrier_id].to_i
    data = EasyModel.tickets_transactions_per_carrier(start_date, end_date, ticket_type_id, warehouse_type_id, carrier_id)

    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      template = (warehouse_type_id == 1) ? 'tickets_transactions_ingredients_per_carrier.yml' : 'tickets_transactions_products_per_carrier.yml'
      filename = (warehouse_type_id == 1) ? 'movimientos_materia_prima_por_mp_por_transportista.pdf' : 'movimientos_producto_terminado_por_pt_por_transportista.pdf'
      report = EasyReport::Report.new data, template
      send_data report.render, :filename => filename, :type => "application/pdf"
    end
  end

  def tickets_transactions_per_driver
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    ticket_type_id = params[:report][:ticket_type_id].to_i
    warehouse_type_id = params[:report][:warehouse_type_id].to_i
    driver_id = params[:report][:driver_id].to_i
    data = EasyModel.tickets_transactions_per_driver(start_date, end_date, ticket_type_id, warehouse_type_id, driver_id)

    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      template = (warehouse_type_id == 1) ? 'tickets_transactions_ingredients_per_driver.yml' : 'tickets_transactions_products_per_driver.yml'
      filename = (warehouse_type_id == 1) ? 'movimientos_materia_prima_por_mp_por_chofer.pdf' : 'movimientos_producto_terminado_por_pt_por_chofer.pdf'
      report = EasyReport::Report.new data, template
      send_data report.render, :filename => filename, :type => "application/pdf"
    end
    
  end

  def alarms
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    by_alarm_type = params[:report][:by_alarm_type_1].to_i
    if by_alarm_type != 0
      alarm_type_id = params[:report][:alarm_type_id_1].to_i
    else
      alarm_type_id = 0
    end

    data = EasyModel.alarms(start_date, end_date, alarm_type_id)

    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'alarms.yml'
      send_data report.render, :filename => 'alarmas.pdf', :type => 'application/pdf'
    end
  end

  def alarms_per_order
    by_alarm_type = params[:report][:by_alarm_type_2].to_i
    if by_alarm_type != 0
      alarm_type_id = params[:report][:alarm_type_id_2].to_i
    else
      alarm_type_id = 0
    end
    data = EasyModel.alarms_per_order(params[:report][:order], alarm_type_id)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'alarms_per_order.yml'
      send_data report.render, :filename => 'alarmas_por_orden.pdf', :type => 'application/pdf'
    end
  end

  def stats
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    data = EasyModel.stats(start_date, end_date)

    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'stats.yml'
      send_data report.render, :filename => 'estadisticas.pdf', :type => 'application/pdf'
    end
  end

  def order_stats
    data = EasyModel.order_stats(params[:report][:order])
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'order_stats.yml'
      send_data report.render, :filename => 'estadisticas_de_orden.pdf', :type => 'application/pdf'
    end
  end
end
