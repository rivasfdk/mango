# encoding: UTF-8

include MangoModule

class ReportsController < ApplicationController

  def index
    @drivers = Driver.where({frequent: true})
    @carriers = Carrier.where({frequent: true})
    @clients = Client.get_all()
    @all_clients = Client.where({factory: false})
    @factories = Client.where({factory: true})
    @alarm_types = AlarmType.all
    @hoppers = Hopper.includes(:scale).where(scales: {not_weighed: false})
    @recipes = Recipe.lastests_by_code()
    @recipes_all = Recipe.where(active: true, in_use: true)
    @units = OrderStatType::UNITS.select {|key, value| OrderStatType.group(:unit).pluck(:unit).include?(key)}
    @ingredients = Ingredient.actives.all
    @products = Product.all
    @lots = Lot.includes(:ingredient).where(active: true).order('id desc')
    mango_features = get_mango_features()
    @real_production_enabled = mango_features.include?("real_production")
    @ingredient_inclusion_enabled = mango_features.include?("ingredient_inclusion")
    @pid_preselected_ingredient_ids = PreselectedIngredientId
      .where(user_id: session[:user_id])
      .where(report: 'production_and_ingredient_distribution')
      .pluck(:ingredient_id)
    @icwp_preselected_ingredient_ids = PreselectedIngredientId
      .where(user_id: session[:user_id])
      .where(report: 'ingredient_consumption_with_plot')
      .pluck(:ingredient_id)
    @preselected_recipe_codes = PreselectedRecipeCode.where(user_id: session[:user_id]).pluck(:recipe_code)
    recipe_types = Recipe::TYPES
    recipe_types.delete(0)
    @recipe_types = recipe_types
  end

  def daily_production
    @data = EasyModel.daily_production(params[:report])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'reports/daily_production'
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def daily_production_details
    @data = EasyModel.daily_production_details(params[:report])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    elsif @data.has_key? :total_orders
      flash[:notice] = "El numero de ordenes totales excede el límite de 200 (Se encontraron #{@data[:total_orders]} ordenes)"
      flash[:type] = 'error'
      redirect_to :action => 'index'
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
    @data = EasyModel.order_duration(params[:report])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'reports/order_duration'
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def order_details
    @data = EasyModel.order_details(params[:report][:order])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      if params[:report][:format] == "xlsx"
        render :xlsx => 'order_details', :filename => "#{@data['title']}.xlsx"
      else
        format = params[:report][:format] || 'pdf'
        render format.to_sym => "order_details", :filename => "#{@data['title']}.#{format}" 
      end
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
    @data = EasyModel.batch_details(params[:report][:order], params[:report][:batch])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'reports/batch_details'
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def hopper_transactions
    start_datetime = EasyModel.param_to_datetime(params[:report], 'start')
    end_datetime = EasyModel.param_to_datetime(params[:report], 'end')
    data = EasyModel.hopper_transactions(params[:report][:hopper_id], start_datetime, end_datetime)
    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'hopper_transactions.yml'
      send_data report.render, :filename => "movimientos_de_tolva.pdf", :type => "application/pdf"
    end
  end

  def consumption_per_recipe
    @data = EasyModel.consumption_per_recipe(params[:report])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      include_real = params[:report][:include_real] == "1"
      ingredient_inclusion = params[:report][:ingredient_inclusion] == "1"
      if params[:report][:format] == "xlsx"
        if include_real
          template_name ='consumption_per_recipe_real'
        elsif ingredient_inclusion
          template_name ='consumption_per_recipe_with_inclusion'
        else
          template_name ='consumption_per_recipe'
        end
        render :xlsx => template_name, :filename => "#{@data['title']}.xlsx"
      else
        if include_real
          template_name = 'consumption_per_recipe_real'
        elsif ingredient_inclusion
          template_name = 'consumption_per_recipe_with_inclusion'
        else
          template_name = 'consumption_per_recipe'
        end
        rendered = render_to_string formats: [:pdf], template: "reports/#{template_name}"
        send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
      end
    end
  end

  def consumption_per_selected_ingredients
    @data = EasyModel.consumption_per_selected_ingredients(params[:report], session[:user_id])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      if params[:report][:format] == "xlsx"
        template_name = params[:report][:include_real] == "1" ?
          'consumption_per_selected_ingredients_real' :
          'consumption_per_selected_ingredients'
        render :xlsx => template_name, :filename => "#{@data['title']}.xlsx"
      else
        template_name = params[:report][:include_real] == "1" ?
        'consumption_per_selected_ingredients_real' : 'consumption_per_selected_ingredients'
        rendered = render_to_string formats: [:pdf], template: "reports/#{template_name}"
        send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
      end
    end
  end

  def consumption_per_ingredient_per_orders
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    ingredient_id = params[:report]['ingredient_id']
    @data = EasyModel.consumption_per_ingredient_per_orders(start_date, end_date, ingredient_id)
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      if params[:report][:format] == "xlsx"
        template_name = params[:report][:include_real] == "1" ?
          'consumption_per_ingredient_per_orders_real' :
          'consumption_per_ingredient_per_orders'
        render :xlsx => template_name, :filename => "#{@data['title']}.xlsx"
      else
        template_name = params[:report][:include_real] == "1" ?
        'consumption_per_ingredient_per_orders_real' : 'consumption_per_ingredient_per_orders'
        rendered = render_to_string formats: [:pdf], template: "reports/#{template_name}"
        send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
      end
    end
  end

  def consumption_per_ingredients
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    @data = EasyModel.consumption_per_ingredients(start_date, end_date)
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    end
    view = params[:report][:include_real] == "1" ?
      :consumption_per_ingredients_real :
      :consumption_per_ingredients
    render view
  end

  def consumption_per_client
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    @data = EasyModel.consumption_per_client(start_date, end_date, params[:report][:client_id])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      if params[:report][:format] == "xlsx"
        template_name = params[:report][:include_real] == "1" ?
          'consumption_per_client_real' : 'consumption_per_client'
        render :xlsx => template_name, :filename => "#{@data['title']}.xlsx"
      else
        template_name = params[:report][:include_real] == "1" ?
          'consumption_per_client_real' : 'consumption_per_client'
        rendered = render_to_string formats: [:pdf], template: "reports/#{template_name}"
        send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
      end
    end
  end

  def stock_adjustments
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')

    @data = EasyModel.stock_adjustments(start_date, end_date)
    if @data.nil?

      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: "reports/stock_adjustments"
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
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
    by_content = params[:report][:by_content] == '1'
    ingredients_id = params[:report][:ingredients_ids_3]
    products_id = params[:report][:products_ids]
    by_factory = params[:report][:by_factory_1] == '1'
    factory_id = params[:report][:factory_id_1]
    factory_id = nil unless factory_id.present?
    if params[:report][:group] == '1'
      @data = EasyModel.simple_stock(content_type, by_factory, factory_id, date, by_content, ingredients_id, products_id)
    else
      @data = EasyModel.simple_stock_per_lot(content_type, by_factory, factory_id, date, by_content, ingredients_id, products_id)
    end
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: "reports/simple_stock"
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def simple_stock_projection
    days = params[:report][:days]
    by_factory = params[:report][:by_factory_2] == '1'
    factory_id = params[:report][:factory_id_2]
    factory_id = nil unless factory_id.present?
    @data = EasyModel.simple_stock_projection(by_factory, factory_id, days)
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: "reports/simple_stock_projection"
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
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
    @data = EasyModel.production_per_recipe(start_date, end_date, params[:report][:recipe_code_2])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'reports/production_per_recipe'
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def production_per_client
    @data = EasyModel.production_per_client(params)
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'reports/production_per_client'
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def order_lots_parameters
    data = EasyModel.order_lots_parameters(params[:report][:order])

    if data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      data, template = DynamicTemplate.generate data, 'order_lots_parameters.yml'
      logger.debug("Plantilla")
      logger.debug(template)
      logger.debug("Datos")
      logger.debug(data)
      report = EasyReport::Report.new data, template
      send_data report.render, :filename => "caracteristicas_de_orden.pdf", :type => "application/pdf"
    end
  end

  def tickets_transactions
    @data = EasyModel.tickets_transactions(params[:report], session[:company]['name'])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      format = params[:report][:format] || 'pdf'
      render format.to_sym => "tickets_transactions", :filename => "#{@data['title']}.#{format}"
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

    @data = EasyModel.alarms(start_date, end_date, alarm_type_id)

    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'reports/alarms'
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def alarms_per_order
    by_alarm_type = params[:report][:by_alarm_type_2].to_i
    if by_alarm_type != 0
      alarm_type_id = params[:report][:alarm_type_id_2].to_i
    else
      alarm_type_id = 0
    end
    @data = EasyModel.alarms_per_order(params[:report][:order], alarm_type_id)
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'reports/alarms_per_order'
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def stats
    @data = EasyModel.stats(params[:report])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      rendered = render_to_string formats: [:pdf], template: 'reports/stats'
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def stats_with_plot
    start_date = EasyModel.param_to_datetime(params[:report], 'start')
    end_date = EasyModel.param_to_datetime(params[:report], 'end')
    @data = EasyModel.stats_with_plot(start_date, end_date, 'degC')
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    end
  end

  def order_stats
    @data = EasyModel.order_stats(params[:report][:order])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    end
  end

  def lot_transactions
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    lot_type = params[:report][:lot_type].to_i
    lot_code = params[:report][:lot_code]

    @data = EasyModel.lot_transactions(start_date, end_date, lot_type, lot_code)
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to action: 'index'
    else
      rendered = render_to_string formats: [:pdf], template: "reports/lot_transactions"
      send_data rendered, filename: "#{@data['title']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def weekly_recipes_versions
    start_week = EasyModel.parse_date(params[:report][:start_week])
    end_week = EasyModel.parse_date(params[:report][:end_week])

    @data = EasyModel.weekly_recipes_versions(start_week, end_week, request.host_with_port)
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to action: 'index'
    end
  end

  def production_and_ingredient_distribution
    @data = EasyModel.production_and_ingredient_distribution(params[:report], session[:user_id])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to reports_path
    end
  end

  def ingredient_consumption_with_plot
    if params[:report][:time_unit] == '1'
      start_date = EasyModel.parse_date(params[:report][:start_week_2])
      end_date = EasyModel.parse_date(params[:report][:end_week_2])
      time_step = 1.week
    else
      start_date = EasyModel.param_to_date(params[:report], 'start_month')
      end_date = EasyModel.param_to_date(params[:report], 'end_month')
      time_step = 1.month
    end
    by_ingredients = params[:report][:by_ingredients] == '1'
    ingredients_ids = params[:report][:ingredients_ids]
    by_recipe = params[:report][:by_recipe_2] == '1'
    recipe_code = params[:report][:recipe_code_3]

    @data = EasyModel.ingredient_consumption_with_plot(start_date, end_date, time_step, by_ingredients, ingredients_ids, by_recipe, recipe_code, session[:user_id])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to reports_path
    end
  end

  def sales
    @data = EasyModel.sales(params[:report])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to reports_path
    end
  end

  def production_note
    @data = EasyModel.production_note(params[:report])
    if @data.nil?
      flash[:notice] = 'No hay registros para generar el reporte'
      flash[:type] = 'warn'
      redirect_to reports_path
    end
  end
end
