include MangoModule
include Rails.application.routes.url_helpers

class EasyModel
  def self.production_note(params)
    n_batch = params[:n_batch].to_i
    return nil if n_batch <= 0

    recipe_id = params[:recipe_id]
    recipe = Recipe
      .includes({ingredient_recipe: {ingredient: {}}})
      .where(id: recipe_id).first
    return nil if recipe.nil?

    data = self.initialize_data('Nota de Producción')
    data[:recipe_code] = recipe.code
    data[:recipe_name] = recipe.name
    data[:recipe_version] = recipe.version
    data[:comment] = recipe.comment
    data[:n_batch] = n_batch
    data[:date] = Date.today.strftime("%d/%m/%Y")

    results = []
    total_production = 0
    total_recipe = 0
    recipe.ingredient_recipe.each do |ir|
      total_amount = ir.amount * n_batch
      results << {
        code: ir.ingredient.code,
        name: ir.ingredient.name,
        amount: ir.amount,
        total_amount: total_amount,
      }
      total_recipe += ir.amount
      total_production += total_amount
    end
    data[:results] = results
    data[:total_recipe] = total_recipe
    data[:total_production] = total_production
    data
  end

  def self.sales(params)
    by_month = params[:date_type] == '1'
    if by_month
      month = EasyModel.param_to_date(params, 'month')
      return nil if month.nil?
      start_date = month.beginning_of_month
      end_date = month.end_of_month
    else
      start_date = EasyModel.param_to_date(params, 'start')
      end_date = EasyModel.param_to_date(params, 'end')
    end

    clients = Client
      .includes(:order)
      .where(orders: {created_at: (start_date .. end_date)})
      .order(:factory)
    clients = clients.where(id: params[:clients_ids]) if params[:by_clients] == '1'
    return nil if clients.empty?

    by_products = params[:by_products] == '1'

    # TODO Usar modelo
    columns = [
      {title: 'P.Inic. (P.I.P)', condition: {recipes: {type_id: 1}}, total: 0},
      {title: 'Poll. (F1)', condition: {recipes: {type_id: 2}}, total: 0},
      {title: 'Poll. (F2)', condition: {recipes: {type_id: 3}}, total: 0},
      {title: 'Pre.Post.', condition: {recipes: {type_id: 4}}, total: 0},
      {title: 'Post-19%', condition: {recipes: {type_id: 5}}, total: 0},
      {title: 'Post-17%', condition: {recipes: {type_id: 6}}, total: 0},
      {title: 'Maquila', condition: {recipes: {type_id: 7}}, total: 0},
      {title: 'Equinos', condition: {recipes: {type_id: 8}}, total: 0},
      {title: 'Cerdos', condition: {recipes: {type_id: 9}}, total: 0},
      {title: 'Vacunos', condition: {recipes: {type_id: 10}}, total: 0},
    ]
    if by_products
      selected_columns = params[:recipe_types_ids].reduce([]) do |selected_columns, recipe_type|
        recipe_type_id = recipe_type.to_i
        if recipe_type_id != 0
          selected_columns << columns[recipe_type_id - 1]
        end
        selected_columns
      end
      columns = selected_columns
    end
    return if columns.empty?
    # TODO

    data = self.initialize_data('Reporte mensual de ventas')
    data[:since] = start_date
    data[:until] = end_date
    data[:by_month] = by_month

    start_stock_total = 0
    end_stock_total = 0
    columns.each_with_index do |column, index|
      product_ids = Recipe
        .where(type_id: column[:condition][:recipes][:type_id])
        .group(:product_id)
        .pluck(:product_id)
      columns[index][:product_ids] = product_ids

      product_lots = ProductLot
        .where(active: true, product_id: product_ids)

      start_stock = 0
      end_stock = 0
      product_lots.each do |product_lot|
        transaction = Transaction
          .where(content_type: 2, content_id: product_lot.id)
          .where(['created_at < ?', start_date])
          .order('created_at desc')
          .first
        unless transaction.nil?
          start_stock += transaction.stock_after / 1000
          start_stock_total += transaction.stock_after / 1000
        end

        transaction = Transaction
          .where(content_type: 2, content_id: product_lot.id)
          .where(['created_at < ?', end_date + 1.day])
          .order('created_at desc')
          .first
        unless transaction.nil?
          end_stock += transaction.stock_after / 1000
          end_stock_total += transaction.stock_after / 1000
        end
      end
      columns[index][:start_stock] = start_stock
      columns[index][:end_stock] = end_stock
    end

    data[:columns] = columns
    data[:start_stock_total] = start_stock_total
    data[:end_stock_total] = end_stock_total

    total = 0
    data[:results] = clients.map do |client|
      row = {}
      row[:client_name] = client.name
      row[:columns] = []
      row[:total] = 0
      columns.each_with_index do |column, index|
        amount = BatchHopperLot
          .joins(batch: {order: {recipe: {}}})
          .where(orders: {created_at: start_date .. end_date + 1.day})
          .where(orders: {client_id: client.id})
          .where(column[:condition])
          .sum(:amount) / 1000
        row[:columns] << amount
        row[:total] += amount
        columns[index][:total] += amount
        total += amount
      end
      row
    end.sort! { |r1, r2| r2[:total] <=> r1[:total] }
    data[:total] = total
    data
  end

  def self.ingredient_consumption_with_plot(start_date, end_date, time_step, by_ingredients, ingredients_ids, by_recipe, recipe_code, user_id)
    if by_ingredients
      PreselectedIngredientId.transaction do
        PreselectedIngredientId.where(user_id: user_id)
          .where(report: 'ingredient_consumption_with_plot').delete_all
        ingredients_ids.each do |ingredient_id|
          PreselectedIngredientId.create ingredient_id: ingredient_id, user_id: user_id, report: 'ingredient_consumption_with_plot'
        end
      end
    end

    return nil if start_date.nil?
    end_date = Date.today if end_date.nil?

    if time_step == 1.week
      start_date = start_date.beginning_of_week
      end_date = end_date.beginning_of_week
      time_steps = ((end_date - start_date).to_i / 7).floor + 1
    else
      start_date = start_date.beginning_of_month
      end_date = end_date.beginning_of_month
      time_steps = (end_date.year - start_date.year) * 12 + end_date.month - start_date.month + 1
    end

    data = self.initialize_data("Consumo por ingredientes y recetas con gráfico")
    data[:start_date] = start_date
    data[:time_steps] = time_steps
    data[:time_step] = time_step
    data[:first_week] = self.get_first_week
    data[:by_ingredients] = by_ingredients

    if by_recipe
      recipe = Recipe.where(code: recipe_code).first
      return nil if recipe.nil?

      data[:recipe] = recipe
    end

    if by_ingredients
      ingredients_ids = Ingredient.where(id: ingredients_ids).pluck(:id)
    else
      ingredients_ids = BatchHopperLot
        .joins({hopper_lot: {lot: {}}, batch: {order: {recipe: {}}}})
        .where(orders: {created_at: start_date .. end_date + time_step})
      ingredients_ids = ingredients_ids.where(recipes: {code: recipe.code}) if by_recipe
      ingredients_ids = ingredients_ids.pluck('DISTINCT lots.ingredient_id')
    end

    ingredients = Ingredient.where(id: ingredients_ids).order(:code)
    return nil if ingredients.empty?

    results = ingredients.reduce({}) do |results, ingredient|
      results[ingredient.id] = {
        ingredient_name: ingredient.name,
        consumptions: []
      }
      results
    end

    time_steps.times do |step|
      offset = time_step == 1.week ? step.weeks : step.months
      time_range = start_date + offset .. start_date + offset + time_step

      consumptions = BatchHopperLot
        .joins({hopper_lot: {lot: {}}, batch: {order: {recipe: {}}}})
        .where(orders: {created_at: time_range})
      consumptions = consumptions.where(lots: {ingredient_id: ingredients_ids}) if by_ingredients
      consumptions = consumptions.where(recipes: {code: recipe.code}) if by_recipe
      consumptions = consumptions
        .select('lots.ingredient_id, SUM(batch_hoppers_lots.amount) AS total')
        .group('lots.ingredient_id')
      consumptions.each do |c|
        results[c[:ingredient_id]][:consumptions] << (c[:total] / 1000).round(2)
      end
      # Ingredients without consumptions
      (ingredients_ids - consumptions.reduce([]) { |ids, c| ids << c[:ingredient_id] }).each do |ingredient_id|
        results[ingredient_id][:consumptions] << nil
      end
    end
    data[:results] = results
    data
  end

  def self.production_and_ingredient_distribution(params, user_id)
    start_date = EasyModel.parse_date(params[:start_date])
    end_date = EasyModel.parse_date(params[:end_date])
    ingredients_ids = params[:ingredients_ids]
    recipe_codes = params[:recipe_codes]
    by_recipe = params[:by_recipe] == "1"

    PreselectedIngredientId.transaction do
      PreselectedIngredientId.where(user_id: user_id)
        .where(report: 'production_and_ingredient_distribution').delete_all
      ingredients_ids.each do |ingredient_id|
        PreselectedIngredientId.create ingredient_id: ingredient_id, user_id: user_id
      end
    end
    PreselectedRecipeCode.transaction do
      PreselectedRecipeCode.where(user_id: user_id).delete_all
      recipe_codes.each do |recipe_code|
        PreselectedRecipeCode.create recipe_code: recipe_code, user_id: user_id
      end
    end

    return nil if start_date.nil?
    return nil if end_date.nil?

    return nil if Order.where(created_at: (start_date .. end_date + 1.day)).empty?

    ingredients = Ingredient
      .select('id, name')
      .where(id: ingredients_ids)
      .order(:code)
      .limit(12)
    return nil if ingredients.empty?

    ingredients_ids = ingredients.pluck(:id)

    ingredient_id_per_column = ingredients_ids
      .each_with_index
      .reduce({}) do |ipc, (ingredient_id, i)|
        ipc[i] = ingredient_id
        ipc
      end

    recipes = Recipe.where(active: true)
    recipes = recipes.where(code: recipe_codes) if by_recipe
    recipes = recipes.group(:code).select('code, name, internal_consumption')
    return nil if recipes.empty?

    recipes = recipes.order('internal_consumption desc, code asc')
      .reduce({}) do |recipes, recipe|
        recipes[recipe[:code].to_sym] = {
          name: recipe[:name],
          internal_consumption: recipe[:internal_consumption]
        }
        recipes
      end

    data = self.initialize_data("Producción y distribución porcentual de materia prima")
    data[:start_date] = start_date
    data[:end_date] = end_date
    data[:ingredients] = ingredients
    data[:ingredient_id_per_column] = ingredient_id_per_column

    data[:results] = recipes.map do |recipe_code, recipe|
      row = {}
      row[:recipe_name] = recipe[:name]
      row[:internal_consumption] = recipe[:internal_consumption]
      row[:versions] = []

      total = BatchHopperLot
        .joins({hopper_lot: {lot: {}},
                batch: {order: {recipe: {}}}})
        .where(orders: {created_at: (start_date .. end_date+ 1.day)},
               recipes: {code: recipe_code})
        .sum(:amount)

      next if total == 0.0

      recipe_versions = Order.joins(:recipe)
        .where(orders: {created_at: (start_date .. end_date + 1.day)})
        .where(recipes: {code: recipe_code})
        .order('orders.created_at')
        .group('recipes.version')
        .pluck_all('recipes.version, MAX(orders.created_at) AS last_used_at')

      recipe_versions.sort! {|v1, v2| v1['last_used_at'] <=> v2['last_used_at']}

      recipe_versions.each do |recipe_version|
        version_total = BatchHopperLot
          .joins({hopper_lot: {lot: {}},
                  batch: {order: {recipe: {}}}})
          .where(orders: {created_at: (start_date .. end_date + 1.day)},
                 recipes: {code: recipe_code, version: recipe_version['version']})
          .sum(:amount)

        percentages = BatchHopperLot
          .joins({hopper_lot: {lot: {}},
                  batch: {order: {recipe: {}}}})
          .select("lots.ingredient_id,
                   SUM(batch_hoppers_lots.amount) / #{version_total} * 100 AS percentage")
          .where(orders: {created_at: (start_date .. end_date + 1.day)},
                 recipes: {code: recipe_code, version: recipe_version['version']},
                 lots: {ingredient_id: ingredients_ids})
          .group('lots.ingredient_id')
          .reduce([{}, 0.0]) do |percentages, percentage|
            p = percentage[:percentage]
            percentages[0][percentage[:ingredient_id]] = p
            percentages[1] += p
            percentages
          end
        first_used_at = Order
          .joins(:recipe)
          .where(['recipes.code = ? and recipes.version != ?', recipe_code, recipe_version['version']])
          .where(['orders.created_at < ?', recipe_version['last_used_at']])
          .order('orders.created_at desc')
          .first.created_at.to_date

        if end_date - start_date > 1
          days = "-"
        else
          days = start_date - first_used_at + 1
        end

        row[:versions] << {
          version: recipe_version['version'],
          days: days,
          total: version_total / 1000,
          percentages: percentages[0],
          percentage_total: percentages[1],
        }
      end
      row
    end.compact

    return nil if data[:results].empty?

    data
  end

  def self.weekly_recipes_versions(start_week, end_week, domain)
    return nil if start_week.nil?

    start_week = start_week.beginning_of_week
    end_week = end_week.nil? ? Date.today.beginning_of_week : end_week.beginning_of_week

    weeks = ((end_week - start_week).to_i / 7).floor + 1

    data = self.initialize_data("Versiones de receta por semana")
    data[:start_week] = start_week
    data[:weeks] = weeks
    data[:first_week] = self.get_first_week
    data[:domain] = domain

    recipes = Recipe
      .joins(:order)
      .group('recipes.code')
      .select('recipes.code, recipes.name, recipes.internal_consumption')
      .where(orders: {created_at: (start_week .. end_week + 1.week)})
      .order('recipes.internal_consumption desc, recipes.code asc')
      .reduce({}) do |recipes, recipe|
        recipes[recipe[:code].to_sym] = {
          name: recipe[:name],
          internal_consumption: recipe[:internal_consumption]
        }
        recipes
      end

    return nil if recipes.empty?

    data[:results] = recipes.map do |recipe_code, recipe|
      row = {}
      row[:recipe_name] = recipe[:name]
      row[:internal_consumption] = recipe[:internal_consumption]
      row[:versions] = []

      weeks.times do |week|
        week_range = start_week + week.weeks .. start_week + week.weeks + 1.week
        row[:versions] << Order
          .joins(:recipe)
          .where(created_at: week_range,
                 recipes: {code: recipe_code})
          .pluck_all('DISTINCT recipes.version, recipes.id')
          .sort_by { |hash| hash["version"] }
          .map { |hash| {version: hash["version"], domain: domain, path: recipe_path(hash["id"]) } }
      end
      row
    end
    data
  end

  def self.lot_transactions(start_date, end_date, lot_type, lot_code)
    lot = lot_type == 1 ? Lot.find_by_code(lot_code) : ProductLot.find_by_code(lot_code)
    return nil if lot.nil?

    content = lot_type == 1 ? lot.ingredient : lot.product

    transactions = Transaction
      .includes(:user, :transaction_type, :order, :ticket)
      .where(notified: true)
      .where(created_at: start_date .. end_date + 1.day)
      .where(content_type: lot_type)
      .where(content_id: lot.id)
    return nil if transactions.empty?

    data = self.initialize_data("Movimientos del Lote #{lot.code} #{content.name}")
    data[:since] = self.print_range_date(start_date)
    data[:until] = self.print_range_date(end_date)
    data[:results] = []

    diff = 0
    transactions.each_with_index do |t, i|
      amount = t.transaction_type.sign == "+" ? t.amount : -1 * t.amount
      stock_after = t.stock_after
      fixed_stock = i == 0 ? t.stock_after : transactions[i - 1].stock_after + amount
      diff += stock_after - fixed_stock if (stock_after - fixed_stock).abs > 0.2
      data[:results] << {
        date: self.print_range_date(t.created_at, true),
        user: t.user.login,
        order: t.order.present? ? t.order.code : "-",
        ticket: t.ticket.present? ? t.ticket.number : "-",
        document_number: t.document_number.present? ? t.document_number : "-",
        type: t.transaction_type.code,
        amount: amount,
        stock: t.stock_after,
        fixed_stock: i == 0 ? t.stock_after : transactions[i - 1].stock_after + amount,
        diff: diff,
        comment: t.comment,
      }
    end
    data[:diff] = diff
    data
  end

  def self.order_lots_parameters(order_code)
    joins = {lot: {hopper_lot: {batch_hopper_lot: {batch: {order: {}}}}}}
    includes = {lot_parameters: {lot_parameter_type: {}}, lot: {ingredient: {}}}
    where = {orders: {code: order_code}}
    lot_parameter_lists = LotParameterList.joins(joins)
                                          .includes(includes)
                                          .where(where)
                                          .order('ingredients.code asc')
    joins = {product_lot: {orders: {}}}
    includes = {product_lot_parameters: {product_lot_parameter_type: {}}, product_lot: {product: {}}}
    where = {orders: {code: order_code}}
    product_lot_parameter_list = ProductLotParameterList.joins(joins)
                                                        .includes(includes)
                                                        .where(where).first

    return nil if lot_parameter_lists.empty? and product_lot_parameter_list.nil?

    order = Order.includes(:batch).where(code: order_code).first
    data = self.initialize_data("Caracteristicas de la orden #{order.code}")
    data['order'] = order.code
    data['client'] = "#{order.client.code} - #{order.client.name}"
    data['recipe'] = "#{order.recipe.code} - #{order.recipe.name}"
    data['version'] = order.recipe.version
    data['product'] = order.product_lot.nil? ? "" : "#{order.product_lot.code} - #{order.product_lot.product.name}"
    data['start_date'] = order.batch.empty? ? "" : order.batch
                                                      .first
                                                      .created_at
                                                      .strftime("%d/%m/%Y %H:%M:%S")
    data['end_date'] = order.batch.empty? ? "" : order.batch
                                                      .last
                                                      .end_date
                                                      .strftime("%d/%m/%Y %H:%M:%S")
    data['tables'] = []

    lot_parameter_lists.each do |lpl|
      data['tables'] << {
        "title" => "#{lpl.lot.ingredient.name} (Lote #{lpl.lot.code})",
        "table" => lpl.parameters_with_range
      }
    end

	  unless product_lot_parameter_list.nil?
	    data['tables'] << {
        "title" => "#{product_lot_parameter_list.product_lot.product.name} (Lote #{product_lot_parameter_list.product_lot.code})",
        "table" => product_lot_parameter_list.parameters_with_range
      }
    end

    data
  end

  def self.hopper_transactions(hopper_id, start_datetime, end_datetime)
    hopper = Hopper.find_by_id hopper_id, :include => :scale
    return nil if hopper.nil?

    includes = {hopper_lot: {lot: {ingredient: {}}}, hopper_lot_transaction_type: {}, user: {}}
    hlts = HopperLotTransaction.includes(includes)
    hlts = hlts.where(created_at: start_datetime .. end_datetime)
    hlts = hlts.where({hoppers_lots: {hopper_id: hopper_id}})
    return nil if hlts.empty?

    data = self.initialize_data("Movimientos de tolva #{hopper.name} (#{hopper.scale.name})")
    data['since'] = self.print_range_date(start_datetime, true)
    data['until'] = self.print_range_date(end_datetime, true)
    data['results'] = []

    hlts.each do |hlt|
      amount = hlt.hopper_lot_transaction_type.sign == "+" ? hlt.amount : -1 * hlt.amount
      data['results'] << {
        'code' => hlt.hopper_lot.lot.code,
        'ingredient' => hlt.hopper_lot.lot.ingredient.name,
        'time' => hlt.created_at.strftime("%d/%m/%Y %H:%M:%S"),
        'user' => hlt.user.login,
        'type' => hlt.hopper_lot_transaction_type.code,
        'amount' => amount,
        'stock' => hlt.stock_after
      }
    end
    data
  end

  def self.stats(start_date, end_date)
    @orders = Order.find :all, :include=>{:order_stats => {}, :batch => {}, :recipe => {}}, :conditions=>['batches.start_date >= ? and batches.end_date <= ?', self.start_date_to_sql(start_date), self.end_date_to_sql(end_date)], :order=>['batches.start_date ASC']

    data = self.initialize_data("Estadisticas de produccion")
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    return nil if @orders.empty?

    @orders.each do |order|
      n1, n2, n3, n4, n5, n6 = 0, 0, 0, 0, 0, 0
      tmp_batch_bal_macro = 0
      tmp_desc_bal_macro = 0
      batches_hora_mezc = 0
      tmp_mol_1 = 0
      tmp_mol_2 = 0
      tmp_mol_3 = 0
      order.order_stats.each do |order_stat|
        if order_stat.order_stat_type_id == 1
          n1 += 1
          tmp_batch_bal_macro += order_stat.value
        elsif order_stat.order_stat_type_id == 2
          n2 += 1
          tmp_desc_bal_macro += order_stat.value
        elsif order_stat.order_stat_type_id == 3
          n3 += 1
          tmp_mol_1 += order_stat.value
        elsif order_stat.order_stat_type_id == 4
          n4 += 1
          tmp_mol_2 += order_stat.value
        elsif order_stat.order_stat_type_id == 5
          n5 += 1
          tmp_mol_3 += order_stat.value
        elsif order_stat.order_stat_type_id == 6
          n6 += 1
          batches_hora_mezc += order_stat.value
        end
      end
      tmp_batch_bal_macro = n1.zero? ? 0 : tmp_batch_bal_macro / n1
      tmp_desc_bal_macro = n2.zero? ? 0 : tmp_desc_bal_macro / n2
      tmp_mol_1 = n3.zero? ? 0 : tmp_mol_1 / n3
      tmp_mol_2 = n4.zero? ? 0 : tmp_mol_2 / n4
      tmp_mol_3 = n5.zero? ? 0 : tmp_mol_3 / n5
      batches_hora_mezc = n6.zero? ? 0 : batches_hora_mezc / n6
      data['results'] << {
        'order' => order.code,
        'recipe_name' => order.recipe.name,
        'real_batches' => order.batch.count,
        'tmp_batch_bal_macro' => self.int_seconds_to_time_string(tmp_batch_bal_macro),
        'tmp_desc_bal_macro' => self.int_seconds_to_time_string(tmp_desc_bal_macro),
        'batches_hora_mezc' => batches_hora_mezc,
        'tmp_mol_1' => self.int_seconds_to_time_string(tmp_mol_1),
        'tmp_mol_2' => self.int_seconds_to_time_string(tmp_mol_2),
        'tmp_mol_3' => self.int_seconds_to_time_string(tmp_mol_3),
      }
    end
    return data
  end

  def self.order_stats(order_code)
    order = Order.find_by_code order_code
    return nil if order.nil?

    data = self.initialize_data('Estadisticas de orden')
    data[:order] = order.code
    data[:client] = "#{order.client.code} - #{order.client.name}"
    data[:recipe] = "#{order.recipe.code} - #{order.recipe.name}"
    data[:version] = order.recipe.version
    data[:comment] = order.comment
    data[:product] = order.product_lot.nil? ? "" : "#{order.product_lot.product.code} - #{order.product_lot.product.name}"
    data[:start_date] = order.batch.empty? ? "" : order.batch
                                                       .first
                                                       .created_at
                                                       .strftime("%d/%m/%Y %H:%M:%S")
    data[:end_date] = order.batch.empty? ? "" : order.batch
                                                     .last
                                                     .end_date
                                                     .strftime("%d/%m/%Y %H:%M:%S")
    data[:real_batches] = order.batch.count.to_s
    data[:results] = []

    stats = OrderStat.joins(:order_stat_type)
                     .where(order_id: order.id)
                     .select('orders_stats_types.description AS stat_name,
                              orders_stats_types.min AS min,
                              orders_stats_types.max AS max,
                              orders_stats_types.unit AS unit,
                              AVG(orders_stats.value) AS stat_avg,
                              MAX(orders_stats.value) AS stat_max,
                              MIN(orders_stats.value) AS stat_min,
                              STD(orders_stats.value) AS stat_std')
                     .group('order_stat_type_id')

    return nil if stats.empty?

    stats.each do |stat|
      data[:results] << {
        stat_name: stat[:stat_name],
        min: stat[:min].nil? ? nil : Unit(stat[:min], stat[:unit]),
        max: stat[:max].nil? ? nil : Unit(stat[:max], stat[:unit]),
        stat_avg: Unit(stat[:stat_avg], stat[:unit]),
        stat_min: Unit(stat[:stat_min], stat[:unit]),
        stat_max: Unit(stat[:stat_max], stat[:unit]),
        stat_std: Unit(stat[:stat_std], stat[:unit])
      }
    end
    data
  end

  def self.stats_with_plot(start_datetime, end_datetime, unit)
    data = self.initialize_data("Estadisticas de produccion")
    data[:since] = self.print_range_date(start_datetime)
    data[:until] = self.print_range_date(end_datetime)
    data[:plot_path] = "#{Rails.root}/tmp/stats_plot.jpg"
    data[:results] = []

    unix_start_datetime = start_datetime.to_i
    unix_end_datetime = (end_datetime + 1.day).to_i

    stats = OrderStat.joins(:order_stat_type)
      .where(orders_stats_types: {unit: unit})
      .where(created_at: unix_start_datetime .. unix_end_datetime)
      .select('orders_stats_types.description AS stat_name,
               orders_stats_types.min AS min,
               orders_stats_types.max AS max,
               orders_stats_types.unit AS unit,
               AVG(orders_stats.value) AS stat_avg,
               MAX(orders_stats.value) AS stat_max,
               MIN(orders_stats.value) AS stat_min,
               STD(orders_stats.value) AS stat_std')
      .group('order_stat_type_id')
    return nil if stats.empty?

    stats.each do |stat|
      data[:results] << {
        stat_name: stat[:stat_name],
        min: stat[:min].nil? ? nil : Unit(stat[:min], stat[:unit]),
        max: stat[:max].nil? ? nil : Unit(stat[:max], stat[:unit]),
        stat_avg: Unit(stat[:stat_avg], stat[:unit]),
        stat_min: Unit(stat[:stat_min], stat[:unit]),
        stat_max: Unit(stat[:stat_max], stat[:unit]),
        stat_std: Unit(stat[:stat_std], stat[:unit])
      }
    end

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.rmargin 5
        plot.lmargin 5

        OrderStatType.where(unit: unit).each do |ost|
          n = OrderStat.where(created_at: unix_start_datetime .. unix_end_datetime).count.to_f / 100
          stats = OrderStat.where(created_at: unix_start_datetime .. unix_end_datetime)
            .where(order_stat_type_id: ost.id)
            .select('AVG(orders_stats.value) AS stat_avg,
                     AVG(orders_stats.created_at) AS stat_avg_unixtime')
            .group("FLOOR(id/#{n})").inject([[], []]) do |array, os|
              array.first << os[:stat_avg_unixtime]
              array.second << os[:stat_avg]
              array
            end
          plot.data << Gnuplot::DataSet.new(stats) { |ds|
            ds.with = "linespoints"
            ds.title = ost.description
          }
        end
        plot.terminal "jpeg size 1560, 912"
        plot.output data[:plot_path]
      end
    end
    data
  end

  def self.order_details_real(order_code)
    _order_details = order_details(order_code)
    return nil if _order_details.nil?
    return nil if _order_details["product_total"].to_f == 0
    return nil unless _order_details["real_production"].present?
    real_production = _order_details["real_production"].to_f
    product_total = _order_details["product_total"].to_f
    _order_details["results"].each do |result|
      real_kg = result["real_kg"]
      std_kg = result["std_kg"]
      real_real_kg = real_kg * real_production / product_total # DAE fer reelz? LOL
      var_kg = real_real_kg - std_kg
      var_perc = var_kg / std_kg * 100
      result["real_real_kg"] = real_real_kg
      result["var_kg"] = var_kg
      result["var_"] = var_perc
    end
    _order_details
  end

  def self.alarms(start_date, end_date, alarm_type_id)
    @alarms = Alarm.where(date: start_date .. end_date + 1.day)
    @alarms = @alarms.where(alarm_type_id: alarm_type_id) if alarm_type_id != 0
    return nil if @alarms.empty?

    data = self.initialize_data("Reporte de alarmas")
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['table'] = []

    @alarms.each do |alarm|
      date = alarm.date.strftime("%d/%m/%Y %H:%M:%S") rescue "???"
      data['table'] << {
          'order_code' => alarm.order.code,
          'date' => date,
          'description' => alarm.description,
        }
    end
    data
  end

  def self.alarms_per_order(order_code, alarm_type_id)
    order = Order.find_by_code order_code
    return nil if order.nil?
    alarms = []
    if alarm_type_id == 0
      alarms = Alarm.where(order_id: order.id)
    else
      alarms = Alarm.where(alarm_type_id: alarm_type_id, order_id: order.id)
    end
    return nil if alarms.empty?

    data = self.initialize_data("Alarmas de Orden #{order_code}")
    data['table'] = []

    alarms.each do |alarm|
      date = alarm.date.strftime("%d/%m/%Y %H:%M:%S") rescue "???"
      data['table'] << {
          'date' => date,
          'description' => alarm.description,
        }
    end
    data
  end

  def self.ticket(ticket_id)
    @ticket = Ticket.find ticket_id
    return nil if @ticket.open?

    data = self.initialize_data("Ticket #{@ticket.number} - #{@ticket.ticket_type.code}")
    data['short_title'] = "Ticket de #{@ticket.ticket_type.code} Romana"

    data['number'] = @ticket.number
    data['incoming_date'] = @ticket.incoming_date.strftime("%d/%m/%Y %H:%M:%S")
    data['outgoing_date'] = @ticket.outgoing_date.strftime("%d/%m/%Y %H:%M:%S")
    if @ticket.ticket_type_id == 1 # Reception ticket
      data['client_title'] = 'Origen:'
    else # Dispatch ticket
      data['client_title'] = 'Destino:'
    end

    data['client_code'] = @ticket.client.code
    data['client_name'] = @ticket.client.name
    data['client_rif'] = @ticket.client.ci_rif
    data['document_type'] = @ticket.document_type.nil? ? "DOCUMENTO" : @ticket.document_type.name
    data['client_address'] = @ticket.address || ""
    data['user_name'] = @ticket.user.name
    data['driver_name'] = @ticket.driver.name
    data['driver_id'] = @ticket.driver.ci
    data['carrier'] = @ticket.truck.carrier.name
    data['license_plate'] = @ticket.truck.license_plate
    data['provider_document_number'] = @ticket.provider_document_number.to_s
    data['incoming_weight'] = @ticket.incoming_weight.to_s + " Kg"
    data['outgoing_weight'] = @ticket.outgoing_weight.to_s + " Kg"
    data['provider_weight'] = @ticket.provider_weight.nil? ? "" : @ticket.provider_weight.to_s + " Kg"
    data['gross_weight'] = @ticket.get_gross_weight.to_s + " Kg"
    data['tare_weight'] = @ticket.get_tare_weight.to_s + " Kg"
    data['net_weight'] = @ticket.get_net_weight.round(2).to_s + " Kg"

    data['comment1'] = " "
    data['comment2'] = " "
    data['comment3'] = " "
    data['comment4'] = " "
    data['comment5'] = " "

    if @ticket.ticket_type_id == 1
      data['dif_label'] = "Dif.:"
      data['dif'] = (@ticket.provider_weight - @ticket.get_net_weight).round(2).to_s + " Kg"
    else
      data['dif_label'] = ""
      data['dif'] = ""
    end

    # I fucking hate easyreport
    data['comment'] = @ticket.comment
    comments = @ticket.comment.split(/\n/)
    comments.each_with_index do |comment, index|
      data["comment#{index + 1}"] = comment
    end

    data['transactions'] = []
    total_amount = 0
    @ticket.transactions.each do |t|
      sacks = ""
      sack_weight = ""
      if t.sack
        sacks = t.sacks.to_s
        sack_weight = t.sack_weight.to_s + " Kg"
      end
      data['transactions'] << {
        'code' => t.get_lot.code,
        'name' => t.get_content.name,
        'sacks' => sacks,
        'sack_weight' => sack_weight,
        'amount' => t.amount,
        'comment' => t.get_lot.comment
      }
      total_amount += t.amount
    end
    data['total_amount'] = total_amount.to_s + " Kg"
    provider_weight = @ticket.provider_weight.nil? ? total_amount : @ticket.provider_weight
    data['perc_dif'] = "#{((@ticket.get_net_weight - provider_weight) / provider_weight * 100).round(2)} %"
    data[:transactions_count] = @ticket.transactions.count
    return data
  end

  def self.tickets_transactions(params, company_name)
    start_date = EasyModel.param_to_date(params, 'start')
    end_date = EasyModel.param_to_date(params, 'end')

    by_ticket_type = params[:by_ticket_type] == '1'
    by_factory = params[:by_factory_3] == '1'
    by_driver = params[:by_driver] == '1'
    by_content = params[:by_ticket_content] == '1'
    by_client = params[:by_client_4] == '1'
    ticket_by_content = params[:ticket_by_content] == '1'

    data = self.initialize_data('Movimientos de Romana')

    transactions = Ticket.base_search
      .where('tickets.open = FALSE')
      .where('tickets.outgoing_date BETWEEN ? AND ?', start_date, end_date + 1.day)

    transactions = transactions.where('tickets.ticket_type_id = ?', params[:ticket_type_id]) if by_ticket_type
    if by_factory
      if params[:factory_id_3].present?
        conditions = ['lots.client_id = ? or products_lots.client_id = ?', params[:factory_id_3], params[:factory_id_3]]
      else
        conditions = 'lots.client_id is null and products_lots.client_id is null'
      end
      transactions = transactions.where(conditions)
    end

    if by_client
      transactions = transactions.where('tickets.client_id = ?', params[:client_id_4])
      data[:client_name] = Client.find(params[:client_id_4]).name
    end
    transactions = transactions.where('tickets.driver_id = ?', params[:driver_id]) if by_driver
    transactions = transactions.where('transactions.content_type = ?', params[:ticket_content_type]) if by_content
    transactions = transactions.where('ingredients.id in (?) or products.id in (?)', params[:ticket_ingredients_ids], params[:ticket_products_ids]) if ticket_by_content
    transactions = transactions.order('tickets.id asc')

    return nil if transactions.empty?

    data[:since] = self.print_range_date(start_date)
    data[:until] = self.print_range_date(end_date)

    data[:ticket_type] = TicketType.where(id: params[:ticket_type_id]).first.code if params[:by_ticket_type] == '1'
    if params[:by_factory_3] == '1'
      data[:factory] = params[:factory_id].present? ? Client.where(id: params[:factory_id_3]).first.name : company_name
    end
    data[:driver_name] = Driver.where(id: params[:driver_id]).first.name if by_driver

    data[:transactions] = transactions.map do |t|
      {
        ticket_number: "#{t[:ticket_number]}\n#{t[:ticket_type]}",
        outgoing_date: t[:ticket_outgoing_date],
        driver_name: t[:driver_name],
        document: "#{t[:document_type]}\n#{t[:document_number]}",
        provider_weight: t[:provider_weight],
        net_weight: t[:transaction_amount],
        diff: "#{(t[:net_weight] - t[:provider_weight]).round(2)}\n(#{((t[:net_weight] - t[:provider_weight]) / t[:provider_weight] * 100).round(2)} %)",
        content_name: t[:content_name],
        lot_code: t[:lot_code],
        client_name: t[:client_name],
        address: t[:ticket_address],
        license_plate: t[:license_plate],
        sack: t[:transaction_sack] == 1 ? "S" : "G"
      }
    end
    data
  end

  def self.daily_production(params)
    start_date = EasyModel.param_to_date(params, 'start')
    end_date = EasyModel.param_to_date(params, 'end')

    by_client = params[:by_client] == '1'
    by_recipe = params[:by_recipe_3] == '1'

    batch_hopper_lots = BatchHopperLot
      .joins({batch: {order: {recipe: {}, client: {}}}})
      .select('orders.code AS order_code,
               MIN(batches.start_date) AS order_start_date,
               recipes.code AS recipe_code,
               recipes.name AS recipe_name,
               recipes.version AS recipe_version,
               clients.code AS client_code,
               clients.name AS client_name,
               MAX(batches.number) AS num_batches,
               SUM(amount) AS total_real,
               SUM(standard_amount) AS total_std')
      .where(orders: {created_at: start_date .. end_date + 1.day})

    batch_hopper_lots = batch_hopper_lots.where({orders: {client_id: params[:client_id_2]}}) if by_client
    batch_hopper_lots = batch_hopper_lots.where({recipes: {code: params[:recipe_code_2]}}) if by_recipe

    batch_hopper_lots = batch_hopper_lots.group('batches.order_id')

    return nil if batch_hopper_lots.empty?

    data = self.initialize_data('Produccion Diaria por Fabrica')
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    batch_hopper_lots.each do |bhl|
      var_kg = bhl[:total_real] - bhl[:total_std]
      var_perc = bhl[:total_std] == 0 ? 100 : var_kg * 100 / bhl[:total_std]
      data['results'] << {
        'order' => bhl[:order_code],
        'date' => bhl[:order_start_date].strftime("%Y-%m-%d"),
        'recipe_code' => bhl[:recipe_code],
        'recipe_name' => bhl[:recipe_name][0..20],
        'recipe_version' => bhl[:recipe_version],
        'client_code' => bhl[:client_code],
        'client_name' => bhl[:client_name],
        'real_batches' => bhl[:num_batches],
        'total_standard' => bhl[:total_std].to_s,
        'total_real' => bhl[:total_real].to_s,
        'var_kg' => var_kg.to_s,
        'var_perc' => var_perc.to_s
      }
    end

    return data
  end

  def self.real_production(start_date, end_date)
    batch_hopper_lots = BatchHopperLot
      .joins({batch: {order: {recipe: {}, client: {}}}})
      .select('orders.code AS order_code,
               MIN(batches.start_date) AS date,
               recipes.name AS recipe_name,
               recipes.version AS recipe_version,
               clients.name AS client_name,
               MAX(batches.number) AS real_batches,
               SUM(amount) AS theoric_total,
               orders.real_production AS real_total')
      .where(batches: {created_at: start_date .. end_date + 1.day})
      .group('batches.order_id')
    return nil if batch_hopper_lots.empty?

    data = self.initialize_data('Produccion Fisico')
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    batch_hopper_lots.each do |bhl|
      rtotal = bhl[:real_total].present? ? bhl[:real_total] : bhl[:theoric_total]
      loss = rtotal - bhl[:theoric_total]
      loss_perc = (loss * 100.0) / bhl[:theoric_total]
      data['results'] << {
        'order' => bhl[:order_code],
        'date' => bhl[:date].strftime("%Y-%m-%d"),
        'recipe_name' => bhl[:recipe_name][0..25],
        'recipe_version' => bhl[:recipe_version],
        'client_name' => bhl[:client_name],
        'real_batches' => bhl[:real_batches],
        'theoric_total' => bhl[:theoric_total],
        'real_total' => rtotal.to_s,
        'loss' => loss.to_s,
        'loss_perc' => loss_perc.to_s
      }
    end

    return data
  end

  def self.consumption_per_ingredient_per_orders(start_date, end_date, ingredient_id)
    ingredient = Ingredient.find_by_id ingredient_id
    return nil if ingredient.nil?

    batch_hopper_lots = BatchHopperLot
      .joins({batch: {order: {recipe: {}}}, hopper_lot: {lot: {}}})
      .select('orders.code AS order_code,
               MIN(batches.start_date) AS start_date,
               recipes.code AS recipe_code,
               recipes.name AS recipe_name,
               recipes.version AS recipe_version,
               orders.prog_batches AS prog_batches,
               COUNT(batches.id) AS real_batches,
               SUM(amount) AS total_real,
               standard_amount AS total_std,
               SUM(real_amount) AS total_real_real')
      .where({orders: {created_at: start_date .. end_date + 1.day, notified: true},
              lots: {ingredient_id: ingredient.id}})
      .group('batches.order_id')

    data = self.initialize_data('Consumo por ingrediente por Ordenes de Produccion')
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []
    data['ingredient'] = "#{ingredient.code} - #{ingredient.name}"

    batch_hopper_lots.each do |bhl|
      bhl[:total_std] *= bhl[:prog_batches]
      var_kg = bhl[:total_real] - bhl[:total_std]
      var_perc = bhl[:total_std] == 0 ? 100 : var_kg * 100 / bhl[:total_std]
      loss = bhl[:total_real_real] - bhl[:total_real]
      loss_perc = (loss * 100.0) / bhl[:total_real]
      data['results'] << {
        'order' => bhl[:order_code],
        'date' => bhl[:start_date].strftime("%Y-%m-%d"),
        'recipe_code' => bhl[:recipe_code],
        'recipe_name' => bhl[:recipe_name],
        'recipe_version' => bhl[:recipe_version],
        'prog_batches' => bhl[:prog_batches],
        'real_batches' => "#{bhl[:real_batches].to_s}/#{bhl[:prog_batches]}",
        'total_standard' => bhl[:total_std].to_s,
        'total_real' => bhl[:total_real].to_s,
        'total_real_real' => bhl[:total_real_real].to_s,
        'var_kg' => var_kg.to_s,
        'var_perc' => var_perc.to_s,
        'loss' => loss,
        'loss_perc' => loss_perc
      }# unless bhl[:real_batches] == bhl[:prog_batches]
    end

    return data
  end

  def self.order_duration(start_date, end_date)
    data = self.initialize_data('Duracion de Orden de Produccion')
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    batch_hopper_lots = BatchHopperLot
                        .joins({batch: {order: {recipe: {}, client: {}}}})
                        .select('orders.code AS order_code, MIN(batches.start_date) AS start_date, MAX(batches.end_date) AS end_date, recipes.name AS recipe_name, MAX(batches.number) AS num_batches, SUM(amount) AS total_real, SUM(standard_amount) AS total_std')
                        .where(batches: {created_at: start_date .. end_date + 1.day})
                        .group('batches.order_id')

    return nil if batch_hopper_lots.empty?

    batch_hopper_lots.each do |bhl|
      order_duration = (bhl[:end_date] - bhl[:start_date]) / 60
      average_batch_duration = order_duration / bhl[:num_batches]
      average_tons_per_hour = bhl[:total_real] / (order_duration / 60) / 1000
      data['results'] << {
        'order' => bhl[:order_code],
        'date' => bhl[:start_date].strftime("%Y-%m-%d"),
        'recipe_name' => bhl[:recipe_name],
        'average_tons_per_hour' => average_tons_per_hour.to_s,
        'average_batch_duration' => average_batch_duration.to_s,
        'order_duration' => order_duration.to_s,
        'real_batches' => bhl[:num_batches],
        'start_time' => bhl[:start_date].strftime('%H:%M:%S'),
        'end_time' => bhl[:end_date].strftime('%H:%M:%S'),
        'total_standard' => bhl[:total_std].to_s,
        'total_real' => bhl[:total_real].to_s
      }
    end

    return data
  end

  def self.daily_production_details(params)
    start_date = EasyModel.param_to_date(params, 'start')
    end_date = EasyModel.param_to_date(params, 'end')

    by_client = params[:by_client_2] == "1"
    Rails.logger.debug "Cliente: #{by_client}"
    by_recipe = params[:by_recipe_4] == "1"

    orders = Order.joins(:recipe).where(orders: {created_at: start_date .. end_date + 1})
    orders = orders.where({orders: {client_id: params[:client_id_3]}}) if by_client
    orders = orders.where(recipes: {code: params[:recipe_code_3]}) if by_recipe
    order_codes = orders.pluck(:code)

    return nil if orders.empty?

    return {total_orders: orders.size} if orders.size > 200

    data = self.initialize_data('Producción diaria con detalle')
    data[:since] = self.print_range_date(start_date)
    data[:until] = self.print_range_date(end_date)
    data[:datas] = []

    order_codes.each do |order_code|
      data[:datas] << order_details(order_code)
    end

    data
  end

  def self.order_details(order_code)
    @order = Order.find_by_code order_code, :include => {:batch => {:batch_hopper_lot => {:hopper_lot => {:hopper => {}, :lot=>{:ingredient=>{}}}}}, :recipe => {:ingredient_recipe => {:ingredient => {}}}, :medicament_recipe => {:ingredient_medicament_recipe => {:ingredient => {}}}, :product_lot => {:product => {}}, :client => {}}
    return nil if @order.nil?

    ingredients = {}
    @order.recipe.ingredient_recipe.each do |ir|
      ingredients[ir.ingredient.code] = ir.amount
    end
    unless @order.medicament_recipe.nil?
      @order.medicament_recipe.ingredient_medicament_recipe.each do |imr|
        ingredients[imr.ingredient.code] = imr.amount.to_f
      end
    end

    details = {}
    n_batch = @order.batch.count
    empty = @order.batch.empty?
    start_date = empty ? "" : @order.batch.first.start_date
    end_date = empty ? "" : @order.batch.last.end_date
    @order.batch.each do |batch|
      batch.batch_hopper_lot.each do |bhl|
        key = bhl.hopper_lot.lot.ingredient.code
        std_amount = (ingredients.has_key?(key)) ? ingredients[key] * n_batch : 0
        hopper_name = bhl.hopper_lot.hopper.name.present? ? bhl.hopper_lot.hopper.name : bhl.hopper_lot.hopper.number
        unless details.has_key?(key)
          details[key] = {
            'ingredient_id' => bhl.hopper_lot.lot.ingredient_id,
            'ingredient' => bhl.hopper_lot.lot.ingredient.name,
            'lot' => bhl.hopper_lot.lot.code,
            'hopper' => hopper_name,
            'real_kg' => bhl.amount.to_f,
            'std_kg' => std_amount.round(2),
            'var_kg' => 0,
            'var_perc' => 0,
          }
        else
          details[key]['real_kg'] += bhl.amount.to_f
        end
        details[key]['real_kg'] = details[key]['real_kg'].round(2)
        details[key]['var_kg'] = details[key]['real_kg'] - details[key]['std_kg']
        details[key]['var_perc'] = details[key]['var_kg'] * 100 / details[key]['std_kg']
      end
    end

    #Add recipe ingredients without any consumption in the order
    ingredients.each do |key, value|
      unless details.has_key?(key)
        std_amount = value * n_batch
        details[key] = {
          'ingredient' => Ingredient.find_by_code(key).name,
          'ingredient_id' => Ingredient.find_by_code(key).id,
          'lot' => "N/A",
          'hopper' => "N/A",
          'real_kg' => 0,
          'std_kg' => std_amount,
          'var_kg' => std_amount,
          'var_perc' => 100,
        }
      end
    end

    total_std = 0
    total_real = 0

    details.each do |key, value|
      total_std += value['std_kg']
      total_real += value['real_kg']
    end

    total_std = total_std.round(2)
    total_real = total_real.round(2)

    total_var = total_real - total_std
    total_var_perc = total_var * 100 / total_std

    data = self.initialize_data('Detalle de Orden de Produccion')
    data['id'] = @order.id
    data['order'] = @order.code
    data['client'] = "#{@order.client.code} - #{@order.client.name}"
    data['recipe_id'] = @order.recipe.id
    data['recipe'] = "#{@order.recipe.code} - #{@order.recipe.name}"
    data['version'] = @order.recipe.version
    data['recipe_comment'] = @order.recipe.comment
    data['comment'] = @order.comment
    data['product'] = @order.product_lot.nil? ? "" : "#{@order.product_lot.code} - #{@order.product_lot.product.name}"
    data['start_date'] = @order.batch.empty? ? "" : @order.batch
                                                          .first
                                                          .created_at
                                                          .strftime("%d/%m/%Y %H:%M:%S")
    data['end_date'] = @order.batch.empty? ? "" : @order.batch
                                                        .last
                                                        .end_date
                                                        .strftime("%d/%m/%Y %H:%M:%S")
    data['prog_batches'] = @order.prog_batches.to_s
    data['real_batches'] = n_batch.to_s
    data['total_std'] = total_std
    data['total_real'] = total_real
    data['total_var'] = total_var
    data['total_var_perc'] = total_var_perc
    data['product_total'] = "#{total_real} Kg"
    data['real_production'] = @order.real_production.present? ? "#{@order.real_production} Kg" : ""
    data['repaired'] = @order.repaired ? "Si" : "No"
    data['results'] = []

    details.sort_by {|k,v| k}.map do |key, value|
      element = {'code' => key}
      data['results'] << element.merge(value)
    end
    return data
  end

  def self.batch_details(order_code, batch_number)
    order = Order.find_by_code(order_code)
    return nil if order.nil?

    batch = Batch.find :first, :include => {:order => {:recipe => {:ingredient_recipe => {:ingredient => {}}}, :medicament_recipe => {:ingredient_medicament_recipe => {:ingredient =>{}}}}}, :conditions => {:number => batch_number, :orders => {:code => order_code}}
    return nil if batch.nil?

    data = self.initialize_data('Detalle de Batch')
    data['order'] = order_code
    data['recipe'] = "#{batch.order.recipe.code} - #{batch.order.recipe.name}"
    data['batch'] = batch_number
    data['start_date'] = batch.created_at.strftime("%d/%m/%Y %H:%M:%S")
    data['end_date'] = batch.end_date.strftime("%d/%m/%Y %H:%M:%S")
    data['results'] = []

    batch_hopper_lots = BatchHopperLot.find :all, :include => {:hopper_lot => {:hopper => {}, :lot => {:ingredient => {}}}}, :conditions => {:batch_id => batch.id}, :order=>['ingredients.code ASC']

    ingredients = {}
    batch.order.recipe.ingredient_recipe.each do |ir|
      ingredients[ir.ingredient.code] = ir.amount
    end

    unless batch.order.medicament_recipe.nil?
      batch.order.medicament_recipe.ingredient_medicament_recipe.each do |imr|
        ingredients[imr.ingredient.code] = imr.amount
      end
    end

    batch_hopper_lots.each do |bhl|
      real_kg = bhl.amount.to_f
      std_kg = 0
      var_kg = 0
      var_perc = 0
      if ingredients.has_key?(bhl.hopper_lot.lot.ingredient.code)
        std_kg = ingredients[bhl.hopper_lot.lot.ingredient.code]
        var_kg = real_kg - std_kg
        var_perc = var_kg * 100 / std_kg rescue 0
      end

      hopper_name = bhl.hopper_lot.hopper.name.present? ? bhl.hopper_lot.hopper.name : bhl.hopper_lot.hopper.number
      data['results'] << {
        'code' => bhl.hopper_lot.lot.ingredient.code,
        'ingredient' => bhl.hopper_lot.lot.ingredient.name,
        'real_kg' => real_kg,
        'std_kg' => std_kg,
        'var_kg' => var_kg,
        'var_perc' => var_perc,
        'hopper' => hopper_name,
        'lot' => bhl.hopper_lot.lot.code,
      }
    end

    return data
  end

  def self.consumption_per_recipe(params)
    start_date = EasyModel.param_to_date(params, 'start_date')
    end_date = EasyModel.param_to_date(params, 'end_date')
    recipe_code = params[:recipe_code]
    ingredient_inclusion = params[:ingredient_inclusion] == '1'
    by_lots = params[:by_lots_recipe] == '1'

    recipe = Recipe.find_by_code recipe_code
    return nil if recipe.nil?

    data = self.initialize_data('Consumo por Receta')
    data['recipe'] = "#{recipe.code} - #{recipe.name}"
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    batch_hopper_lots = BatchHopperLot
      .joins({hopper_lot: {lot: {ingredient: {}}},
              batch: {order: {recipe: {}}}})
      .select('lots.code AS lot_code,
               ingredients.code AS ingredient_code,
               ingredients.name AS ingredient_name,
               SUM(amount) AS total_real,
               SUM(standard_amount) AS total_std,
               SUM(real_amount) AS total_real_real')
      .where({orders: {created_at: start_date .. end_date + 1.day, notified: true},
              recipes: {code: recipe.code}})
      .order('ingredients.code')
      .group(by_lots ? 'lots.id' : 'ingredients.id')

    return nil if batch_hopper_lots.empty?

    total_real = 0
    total_std = 0

    batch_hopper_lots.each do |bhl|
      var_kg = bhl[:total_real] - bhl[:total_std]
      var_perc = var_kg * 100 / bhl[:total_std]
      loss = bhl[:total_real_real] - bhl[:total_real]
      loss_perc = (loss * 100.0) / bhl[:total_real]
      total_real += bhl[:total_real]
      total_std += bhl[:total_std]
      data['results'] << {
        'ingredient_code' => bhl[by_lots ? :lot_code : :ingredient_code],
        'ingredient_name' => bhl[:ingredient_name],
        'std_kg' => bhl[:total_std],
        'real_kg' => bhl[:total_real],
        'real_real_kg' => bhl[:total_real_real],
        'var_kg' => var_kg,
        'var_perc' => var_perc,
        'loss' => loss,
        'loss_perc' => loss_perc
      }
    end

    data['results'].each do |result|
      result['std_incl'] = result['std_kg'] / total_std * 100
      result['real_incl'] = result['real_kg'] / total_real * 100
    end

    return data
  end

  def self.consumption_per_selected_ingredients(params, user_id)
    start_date = EasyModel.param_to_date(params, 'start')
    end_date = EasyModel.param_to_date(params, 'end')
    ingredients_ids = params[:ingredients_ids_2]
    by_lots = params[:by_lots] == '1'
    by_select_ingredients = params[:by_select_ingredients] == '1'
    data = self.initialize_data('Consumo por Ingrediente')
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    return nil if ingredients_ids.empty?

    PreselectedIngredientId.transaction do
      PreselectedIngredientId.where(user_id: user_id)
        .where(report: 'ingredient_consumption_with_plot').delete_all
      ingredients_ids.each do |ingredient_id|
        PreselectedIngredientId.create ingredient_id: ingredient_id, user_id: user_id, report: 'ingredient_consumption_with_plot'
      end
    end

    batch_hopper_lots = BatchHopperLot
      .joins({hopper_lot: {lot: {ingredient: {}}}, batch: {order: {}}})
      .select('lots.code AS lot_code,
               ingredients.code AS ingredient_code,
               ingredients.name AS ingredient_name,
               SUM(amount) AS total_real,
               SUM(standard_amount) AS total_std,
               SUM(real_amount) AS total_real_real')
      .where({orders: {created_at: start_date .. end_date + 1.day, notified: true}})


    batch_hopper_lots = batch_hopper_lots.where(ingredients: {id: ingredients_ids}) if by_select_ingredients
    batch_hopper_lots = batch_hopper_lots.order('ingredients.code')
      .group(by_lots ? 'lots.id' : 'ingredients.id')

    return nil if batch_hopper_lots.empty?

    batch_hopper_lots.each do |bhl|
      var_kg = bhl[:total_real] - bhl[:total_std]
      var_perc = bhl[:total_std] == 0 ? 100 : var_kg * 100 / bhl[:total_std]
      loss = bhl[:total_real_real] - bhl[:total_real]
      loss_perc = (loss * 100.0) / bhl[:total_real]
      data['results'] << {
        'ingredient_code' => bhl[by_lots ? :lot_code : :ingredient_code],
        'ingredient_name' => bhl[:ingredient_name],
        'real_kg' => bhl[:total_real],
        'std_kg' => bhl[:total_std],
        'real_real_kg' => bhl[:total_real_real].to_s,
        'var_kg' => var_kg,
        'var_perc' => var_perc,
        'loss' => loss,
        'loss_perc' => loss_perc
      }
    end

    return data
  end

  def self.consumption_per_client(start_date, end_date, client_id)
    client = Client.find(client_id)
    return nil if client.nil?

    data = self.initialize_data('Consumo por Cliente')
    data['client'] = "#{client.code} - #{client.name}"
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    batch_hopper_lots = BatchHopperLot
      .joins({hopper_lot: {lot: {ingredient: {}}}, batch: {order: {}}})
      .select('ingredients.code AS ingredient_code,
               ingredients.name AS ingredient_name,
               SUM(amount) AS total_real,
               SUM(standard_amount) AS total_std,
               SUM(real_amount) AS total_real_real')
      .where({orders: {created_at: start_date..end_date + 1.day, client_id: client_id, notified: true}})
      .order('ingredients.code')
      .group('ingredients.id')

    return nil if batch_hopper_lots.empty?

    batch_hopper_lots.each do |bhl|
      var_kg = bhl[:total_real] - bhl[:total_std]
      var_perc = bhl[:total_std] == 0 ? 100 : var_kg * 100 / bhl[:total_std]
      loss = bhl[:total_real_real] - bhl[:total_real]
      loss_perc = (loss * 100.0) / bhl[:total_real]
      data['results'] << {
        'ingredient_code' => bhl[:ingredient_code],
        'ingredient_name' => bhl[:ingredient_name],
        'real_kg' => bhl[:total_real],
        'std_kg' => bhl[:total_std],
        'real_real_kg' => bhl[:total_real_real],
        'var_kg' => var_kg,
        'var_perc' => var_perc,
        'loss' => loss,
        'loss_perc' => loss_perc
      }
    end

    return data
  end

  def self.stock_adjustments(start_date, end_date)
    transaction_types = TransactionType.find :all
    adjustment_type_ids = []
    transaction_types.each do |ttype|
      unless ttype.code.match(/(?i)AJU/).nil?
        puts "Adjusment code found: " + ttype.code
        adjustment_type_ids << ttype.id
      end
    end
    return nil if adjustment_type_ids.length.zero?

    adjustments = Transaction.find :all, :conditions => {:transaction_type_id => adjustment_type_ids, :created_at => (start_date)..((end_date) + 1.day)}, :order=>['created_at DESC']
    return nil if adjustments.length.zero?

    data = self.initialize_data('Ajustes de Existencias')
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    adjustments.each do |a|
      lot = a.get_lot
      lot_code = lot.code
      content_code = ''
      content_name = ''
      if a.content_type == 1 # content = lot
        content_code = lot.ingredient.code
        content_name = lot.ingredient.name
      else # content = product lot
        content_code = lot.product.code
        content_name = lot.product.name
      end
      transaction_type_id = a.transaction_type_id
      sign = TransactionType.find(transaction_type_id).sign
      ttype_code = TransactionType.find(transaction_type_id).code
      amount = a.amount
      if sign == '-'
        amount = -1 * amount
      end

      data['results'] << {
        'lot_code' => lot_code,
        'content_code' => content_code,
        'content_name' => content_name,
        'amount' => amount.to_s,
        'user_name' => a.user.login,
        'comment' => a.comment,
        'date' => self.print_range_date(a.created_at),
        'adjustment_code' => ttype_code
      }
    end

    return data
  end

  def self.lots_incomes(start_date, end_date)
    income_type = TransactionType.find :first, :conditions => {:code => 'EN-COM'}
    "Income code found: " + income_type.code
    return nil if income_type.nil?

    incomes = Transaction.find :all, :conditions => {:transaction_type_id => income_type, :created_at => (start_date)..((end_date) + 1.day)}, :order=>['created_at DESC']
    return nil if incomes.length.zero?

    data = self.initialize_data('Entradas de Materia Prima')
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    incomes.each do |i|
      lot = i.get_lot
      lot_code = lot.code
      content_code = ''
      content_name = ''
      if i.content_type == 1
        content_code = lot.ingredient.code
        content_name = lot.ingredient.name
        transaction_type_id = i.transaction_type_id
        sign = TransactionType.find(transaction_type_id).sign
        ttype_code = TransactionType.find(transaction_type_id).code
        amount = i.amount
        if sign == '-'
          amount = -1 * amount
        end

        data['results'] << {
          'lot_code' => lot_code,
          'content_code' => content_code,
          'content_name' => content_name,
          'amount' => amount.to_s,
          'user_name' => i.user.login,
          'date' => self.print_range_date(i.created_at)
        }
      end
    end

    return data
  end

  def self.simple_stock_per_lot(content_type, by_factory, factory_id, date, by_content, ingredients_id, products_id)
    title = (content_type == 1) ? 'Existencias de Materia Prima por lotes' : 'Existencias de Producto Terminado por lotes'
    data = self.initialize_data(title)
    data['date'] = self.print_range_date(date)
    data['results'] = []

    date += 7.hours
    lots = []
    if content_type == 1
      lots = Lot.joins(:ingredient)
      lots = lots.where(:active => true)
      lots = lots.where(:client_id => factory_id) if by_factory
      lots = lots.where(:ingredient_id => ingredients_id) if by_content
      lots = lots.order('ingredients.code, lots.code asc')
    else
      lots = ProductLot.joins(:product)
      lots = lots.where(:active => true)
      lots = lots.where(:client_id => factory_id) if by_factory
      lots = lots.where(:product_id => products_id) if by_content
      lots = lots.order('products.code, products_lots.code asc')
    end
    lots.each do |lot|
      transaction = Transaction.first :conditions => [
        'notified = true and created_at < ? and content_type = ? and content_id = ? ',
        date.strftime("%Y-%m-%d %H:%M:%S"), content_type, lot.id
      ], :order => ['created_at desc']
      if transaction
        data['results'] << {
          'code' => lot.code,
          'name' => lot.get_content.name,
          'stock' => transaction.stock_after
        }
      else
        data['results'] << {
          'code' => lot.code,
          'name' => lot.get_content.name,
          'stock' => 0
        }
      end
    end
    data
  end

  def self.simple_stock(content_type, by_factory, factory_id, date, by_content, ingredients_id, products_id)
    title = (content_type == 1) ? 'Existencias de Materia Prima' : 'Existencias de Producto Terminado'
    data = self.initialize_data(title)
    data['date'] = self.print_range_date(date)
    data['results'] = []

    results = {}
    date += 7.hours
    if content_type == 1
      lots = Lot.order('code asc')
      lots = lots.where(:active => true)
      lots = lots.where(:client_id => factory_id) if by_factory
      lots = lots.where(:ingredient_id => ingredients_id) if by_content
    else
      lots = ProductLot.order('code asc')
      lots = lots.where(:active => true)
      lots = lots.where(:client_id => factory_id) if by_factory
      lots = lots.where(:product_id => products_id) if by_content
    end

    return nil if lots.empty?

    lots.each do |l|
      key = l.get_content.code
      transaction = Transaction.first :conditions => [
        'notified = true and created_at < ? and content_type = ? and content_id = ? ',
        date.strftime("%Y-%m-%d %H:%M:%S"), content_type, l.id
      ], :order => ['created_at desc']
      if transaction
        if results.has_key?(key)
          results[key]['stock'] += transaction.stock_after
        else
          results[key] = {
            'code' => key,
            'name' => l.get_content.name,
            'stock' => transaction.stock_after
          }
        end
      else
        results[key] = {
          'code' => key,
          'name' => l.get_content.name,
          'stock' => 0
        }
      end
    end
    results.sort_by {|k,v| k}.map do |key, item|
      data['results'] << item
    end
    data
  end

  def self.simple_stock_projection(by_factory, factory_id, days)
    days = days.to_i
    return nil if days <= 0

    data = self.initialize_data("Proyeccion de Materia Prima")
    data['date'] = self.print_range_date(Date.today)
    data['days'] = days.to_s

    lots = Lot.where(active: true)
    lots = lots.where(client_id: factory_id) if by_factory
    stocks = lots.group(:ingredient_id).sum(:stock)

    return nil if stocks.empty?

    today = Date.today
    batch_hopper_lots = BatchHopperLot.joins({hopper_lot: {lot: {ingredient: {}}}})
    batch_hopper_lots = batch_hopper_lots.joins(batch: {order: {}})
                                         .where(orders: {client_id: factory_id}) if by_factory and factory_id.present?
    batch_hopper_lots = batch_hopper_lots.where(batch_hoppers_lots: {created_at: (today - days) .. today})
                                         .select('ingredients.id AS ingredient_id,
                                                  ingredients.code AS ingredient_code,
                                                  ingredients.name AS ingredient_name,
                                                  SUM(amount) AS total_real')
                                         .order('ingredients.code')
                                         .group('ingredients.id')

    return nil if batch_hopper_lots.empty?

    data['results'] = batch_hopper_lots.inject([]) do |results, bhl|
      stock = stocks[bhl[:ingredient_id]]
      unless stock.nil?
        projection = (stock / (bhl[:total_real] / days)).to_i
        results << {
          'code' => bhl[:ingredient_code],
          'name' => bhl[:ingredient_name],
          'stock' => stock,
          'projection' => projection < 0 ? 0 : projection
        }
      end
      results
    end
    return data
  end

  def self.product_lots_dispatches(start_date, end_date, doc_number)
    if doc_number.blank?
      conditions = {:transaction_type_id=>5, :created_at => (start_date)..((end_date) + 1.day)}
    else
      conditions = {:transaction_type_id=>5, :transactions=>{:document_number=>doc_number}, :created_at => (start_date)..((end_date) + 1.day)}
    end

    dispatches = Transaction.find :all, :conditions => conditions, :order=>['created_at DESC']
    return nil if dispatches.length.zero?

    data = self.initialize_data('Despacho de producto terminado')
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    dispatches.each do |d|
      if d.content_type == 2
        product_lot = d.get_lot

        data['results'] << {
          'lot_code' => product_lot.code,
          'doc_number' => d.document_number || '--',
          'content_code' => product_lot.product.code,
          'content_name' => product_lot.product.name,
          'amount' => d.amount.to_s,
          'user_name' => d.user.login,
          'comment' => d.comment,
          'date' => self.print_range_date(d.created_at),
          'adjusment_code' => d.transaction_type.code,
        }
      end
    end
    return nil if data['results'].empty?
    return data
  end

  def self.production_per_recipe(start_date, end_date, recipe_code)
    recipe = Recipe.find_by_code recipe_code
    return nil if recipe.nil?

    data = self.initialize_data('Produccion por Receta')
    data['recipe'] = "#{recipe.code} - #{recipe.name}"
    data['version'] = recipe.version
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    batch_hopper_lots = BatchHopperLot
                        .joins({batch: {order: {recipe: {}, client: {}}}})
                        .select('orders.code AS order_code, clients.code AS client_code, clients.name AS client_name, MAX(batches.number) as num_batches, SUM(amount) AS total_real, SUM(standard_amount) AS total_std')
                        .where({orders: {created_at: start_date..end_date + 1.day}, recipes: {code: recipe.code}})
                        .group('batches.order_id')

    return nil if batch_hopper_lots.empty?

    batch_hopper_lots.each do |bhl|
      data['results'] << {
        'order' => bhl[:order_code],
        'client_code' => bhl[:client_code],
        'client_name' => bhl[:client_name],
        'real_batches' => bhl[:num_batches],
        'std_kg' => bhl[:total_std].to_s,
        'real_kg' => bhl[:total_real].to_s,
      }
    end

    return data
  end

  def self.production_per_client(params)
    start_date = EasyModel.param_to_date(params[:report], 'start')
    end_date = EasyModel.param_to_date(params[:report], 'end')
    client = Client.find params[:report][:client_id2] rescue nil
    return nil if client.nil?

    by_product = params[:report][:by_products_2] == '1'

    data = self.initialize_data('Produccion por Cliente')
    data['client'] = "#{client.ci_rif} - #{client.name}"
    data['since'] = self.print_range_date(start_date)
    data['until'] = self.print_range_date(end_date)
    data['results'] = []

    batch_hopper_lots = BatchHopperLot
                        .joins({batch: {order: {recipe: {}, product_lot: {}}}})
                        .select('orders.code AS order_code, recipes.code AS recipe_code, recipes.name AS recipe_name, MAX(batches.number) as num_batches, SUM(amount) AS total_real, SUM(standard_amount) AS total_std')
                        .where({orders: {created_at: start_date..end_date + 1.day, client_id: client.id}})
    batch_hopper_lots = batch_hopper_lots.where({products_lots: {product_id: params[:report][:products_ids]}}) if by_product

    batch_hopper_lots = batch_hopper_lots.group('batches.order_id')

    return nil if batch_hopper_lots.empty?

    batch_hopper_lots.each do |bhl|
      data['results'] << {
        'order' => bhl[:order_code],
        'recipe_code' => bhl[:recipe_code],
        'recipe_name' => bhl[:recipe_name],
        'real_batches' => bhl[:num_batches],
        'std_kg' => bhl[:total_std],
        'real_kg' => bhl[:total_real],
      }
    end

    return data
  end

  # ================================================================
  # Utilities
  # ================================================================

  def self.param_to_date(param, name)
    year = param["#{name}(1i)"].to_i
    month = param["#{name}(2i)"].to_i
    day = param["#{name}(3i)"].to_i
    return Date.new(year, month, day)
  end

  def self.param_to_datetime(param, name)
    year = param["#{name}(1i)"].to_i
    month = param["#{name}(2i)"].to_i
    day = param["#{name}(3i)"].to_i
    hour = param["#{name}(4i)"].to_i
    min = param["#{name}(5i)"].to_i
    return Time.new(year, month, day, hour, min)
  end

  def self.parse_date(date)
    date.present? ? Date.parse(date) : nil
  end

  def self.print_formatted_date(date)
    date.strftime("%d/%m/%Y")
  end

  def self.start_date_to_sql(date)
    date.strftime("%Y-%m-%d")
  end

  def self.end_date_to_sql(date)
    (date + 1.day).strftime("%Y-%m-%d")
  end

  def self.print_range_date(str_date, with_time=false)
    fmt = with_time ? "%d/%m/%Y %H:%M:%S" : "%d/%m/%Y"
    return str_date.strftime(fmt)
  end

  def self.int_seconds_to_time_string(seconds)
    if seconds < 60
      Time.at(seconds).gmtime.strftime('%Ss')
    elsif seconds < 3600
      Time.at(seconds).gmtime.strftime('%Mm:%Ss')
    else
      Time.at(seconds).gmtime.strftime('%Hh%Mm:%Ss')
    end
  end

  def self.get_first_week
    Date.new(Date.today.year, get_mango_field('first_week_month'))
      .beginning_of_month
      .strftime('%U').to_i
  end

  private

  def self.initialize_data(title)
    company = YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['application']
    puts company.inspect
    data = {}
    data['title'] = title
    data['company_name'] = company['name']
    data['company_address'] = company['address']
    data['company_rif'] = company['rif']
    data['company_logo'] = "#{Rails.root.to_s}/app/assets/images/default-report-logo.png"
    data['footer'] = company['footer']
    data
  end
end
