# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

#para que pluralice en castellano - WY
#Inflector.inflections.clear
ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural /([aeriout])([A-Z]|_|$)/, '\1s\2'
  #inflect.plural /([rlnd])([A-Z]|_|$)/, '\1es\2'
  inflect.singular /([aeriout])s([A-Z]|_|$)/, '\1\2'
  #inflect.singular /([rlnd])es([A-Z]|_|$)/, '\1\2'

  # Models with weird pluralized table names because of reasons
  [
    ['base_unit', 'bases_units'],
    ['ingredient_recipe', 'ingredients_recipes'],
    ['parameter_list', 'parameters_lists'],
    ['document_type', 'documents_types'],
    ['hopper_factory_lot', 'hoppers_factory_lots'],
    ['hopper_lot', 'hoppers_lots'],
    ['hopper_lot_transaction', 'hoppers_lots_transaction'],
    ['hopper_lot_transaction_type', 'hoppers_lots_transaction_types'],
    ['ingredient_medicament_recipe', 'ingredients_medicaments_recipes'],
    ['ingredient_parameter_type_range', 'ingredients_parameters_types_ranges'],
    ['last_imported_recipe', 'lasts_imported_recipes'],
    ['lot_parameter', 'lots_parameters'],
    ['lot_parameter_list', 'lots_parameters_lists'],
    ['lot_parameter_type', 'lots_parameters_types'],
    ['medicament_recipe', 'medicaments_recipes'],
    ['order_area', 'orders_areas'],
    ['order_number', 'orders_numbers'],
    ['order_stat', 'orders_stats'],
    ['order_stat_type', 'orders_stats_types'],
    ['parameter_type', 'parameters_types'],
    ['preselected_recipe_code', 'preselected_recipes_codes'],
    ['product_lot', 'products_lots'],
    ['product_lot_parameter', 'products_lots_parameters'],
    ['product_lot_parameter_list', 'products_lots_parameters_lists'],
    ['product_lot_parameter_type', 'products_lots_parameters_types'],
    ['product_parameter_type_range', 'products_parameters_types_ranges'],
    ['ticket_number', 'tickets_numbers'],
    ['ticket_type', 'tickets_types']
  ].each { |i| inflect.irregular i.first, i.second }

end
# extender la clase Inflector
module Inflector
  def pluralize(word)
    result = word.to_s.dup

    if word.empty? || inflections.uncountables.include?(result.downcase)
      result
    else
      inflections.plurals.each { |(rule, replacement)| result.gsub!(rule, replacement) }
      result
    end
  end

  def singularize(word)
    result = word.to_s.dup
    if inflections.uncountables.include?(result.downcase)
      result
    else
      inflections.singulars.each { |(rule, replacement)| result.gsub!(rule, replacement) }
      result
    end
  end
end
