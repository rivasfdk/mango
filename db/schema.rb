# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161109011003) do

  create_table "addresses", force: true do |t|
    t.integer  "client_id",  null: false
    t.string   "address",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "alarm_types", force: true do |t|
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "alarms", force: true do |t|
    t.integer  "order_id"
    t.datetime "date"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "alarm_type_id", default: 1
  end

  add_index "alarms", ["alarm_type_id"], name: "index_alarms_on_alarm_type_id", using: :btree
  add_index "alarms", ["order_id"], name: "fk_alarms_order_id", using: :btree

  create_table "areas", force: true do |t|
    t.string   "description", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "bases_units", force: true do |t|
    t.string   "code",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "batch_hoppers_lots", force: true do |t|
    t.integer  "batch_id"
    t.integer  "hopper_lot_id"
    t.float    "amount",                        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "standard_amount", default: 0.0, null: false
    t.float    "real_amount"
  end

  add_index "batch_hoppers_lots", ["batch_id"], name: "fk_batch_hoppers_lots_batch_id", using: :btree
  add_index "batch_hoppers_lots", ["hopper_lot_id"], name: "fk_batch_hoppers_lots_hopper_lot_id", using: :btree

  create_table "batches", force: true do |t|
    t.integer  "order_id"
    t.integer  "schedule_id"
    t.integer  "user_id"
    t.integer  "number"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "batches", ["order_id"], name: "fk_batches_order_id", using: :btree
  add_index "batches", ["schedule_id"], name: "fk_batches_schedule_id", using: :btree
  add_index "batches", ["user_id"], name: "fk_batches_user_id", using: :btree

  create_table "carriers", force: true do |t|
    t.string   "code",                      null: false
    t.string   "rif"
    t.string   "name",                      null: false
    t.string   "email"
    t.string   "address"
    t.string   "tel1"
    t.string   "tel2"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "frequent",   default: true
  end

  create_table "clients", force: true do |t|
    t.string   "code",                       null: false
    t.string   "name",                       null: false
    t.string   "ci_rif",                     null: false
    t.string   "address"
    t.string   "tel1"
    t.string   "tel2"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "factory",    default: false
  end

  create_table "display_units", force: true do |t|
    t.integer  "base_unit_id"
    t.string   "code",         null: false
    t.float    "rate",         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents_types", force: true do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "drivers", force: true do |t|
    t.string   "name",                      null: false
    t.string   "ci",                        null: false
    t.string   "address"
    t.string   "tel1"
    t.string   "tel2"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "frequent",   default: true
  end

  create_table "hoppers", force: true do |t|
    t.integer  "number",                               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                default: " "
    t.integer  "scale_id",                             null: false
    t.boolean  "main",                default: false
    t.float    "capacity",            default: 1000.0, null: false
    t.boolean  "stock_below_minimum", default: false
  end

  add_index "hoppers", ["scale_id"], name: "fk_hoppers_scale_id", using: :btree

  create_table "hoppers_factory_lots", force: true do |t|
    t.integer  "hopper_lot_id"
    t.integer  "client_id"
    t.integer  "lot_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "hoppers_factory_lots", ["client_id"], name: "fk_hoppers_factory_lots_client_id", using: :btree
  add_index "hoppers_factory_lots", ["hopper_lot_id"], name: "fk_hoppers_factory_lots_hopper_lot_id", using: :btree
  add_index "hoppers_factory_lots", ["lot_id"], name: "fk_hoppers_factory_lots_lot_id", using: :btree

  create_table "hoppers_lots", force: true do |t|
    t.integer  "hopper_id"
    t.integer  "lot_id"
    t.boolean  "active",     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "stock",      default: 0.0
    t.boolean  "factory",    default: false, null: false
  end

  add_index "hoppers_lots", ["hopper_id"], name: "fk_hoppers_lots_hopper_id", using: :btree
  add_index "hoppers_lots", ["lot_id"], name: "fk_hoppers_lots_lot_id", using: :btree

  create_table "hoppers_lots_transaction", force: true do |t|
    t.integer  "hopper_lot_transaction_type_id", null: false
    t.integer  "hopper_lot_id",                  null: false
    t.integer  "user_id",                        null: false
    t.string   "code",                           null: false
    t.date     "date",                           null: false
    t.float    "amount",                         null: false
    t.float    "stock_after",                    null: false
    t.string   "comment"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "hoppers_lots_transaction", ["created_at"], name: "index_hoppers_lots_transaction_on_created_at", using: :btree
  add_index "hoppers_lots_transaction", ["hopper_lot_id"], name: "fk_hoppers_lots_transaction_hopper_lot_id", using: :btree
  add_index "hoppers_lots_transaction", ["hopper_lot_transaction_type_id"], name: "fk_hoppers_lots_transaction_hopper_lot_transaction_type_id", using: :btree
  add_index "hoppers_lots_transaction", ["user_id"], name: "fk_hoppers_lots_transaction_user_id", using: :btree

  create_table "hoppers_lots_transaction_types", force: true do |t|
    t.string   "code",        null: false
    t.string   "description", null: false
    t.string   "sign",        null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "ingredients", force: true do |t|
    t.string   "code",                                null: false
    t.string   "name",                                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "base_unit_id"
    t.float    "minimum_stock",       default: 0.0,   null: false
    t.boolean  "stock_below_minimum", default: false, null: false
    t.boolean  "active",              default: true,  null: false
    t.float    "loss",                default: 0.0,   null: false
  end

  create_table "ingredients_medicaments_recipes", force: true do |t|
    t.integer  "ingredient_id"
    t.integer  "medicament_recipe_id"
    t.float    "amount",               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ingredients_medicaments_recipes", ["ingredient_id"], name: "fk_ingredients_medicaments_recipes_ingredient_id", using: :btree
  add_index "ingredients_medicaments_recipes", ["medicament_recipe_id"], name: "fk_ingredients_medicaments_recipes_medicament_recipe_id", using: :btree

  create_table "ingredients_parameters_types_ranges", force: true do |t|
    t.integer  "ingredient_id",         null: false
    t.integer  "lot_parameter_type_id", null: false
    t.float    "max"
    t.float    "min"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "ingredients_parameters_types_ranges", ["ingredient_id"], name: "fk_ingredient_id", using: :btree
  add_index "ingredients_parameters_types_ranges", ["lot_parameter_type_id"], name: "fk_lot_parameter_type_id", using: :btree

  create_table "ingredients_recipes", force: true do |t|
    t.integer  "ingredient_id"
    t.integer  "recipe_id"
    t.float    "amount",        null: false
    t.integer  "priority",      null: false
    t.float    "percentage",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ingredients_recipes", ["ingredient_id"], name: "fk_ingredients_recipes_ingredient_id", using: :btree
  add_index "ingredients_recipes", ["recipe_id"], name: "fk_ingredients_recipes_recipe_id", using: :btree

  create_table "lasts_imported_recipes", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_recipes",    default: 0
    t.integer  "imported_recipes", default: 0
  end

  create_table "lots", force: true do |t|
    t.string   "code"
    t.string   "location"
    t.integer  "ingredient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "client_id"
    t.boolean  "active",                                 default: true
    t.boolean  "in_use",                                 default: true
    t.decimal  "stock",         precision: 15, scale: 4, default: 0.0,  null: false
    t.float    "density",                                default: 1.0,  null: false
    t.string   "comment"
  end

  add_index "lots", ["ingredient_id"], name: "fk_lots_ingredient_id", using: :btree

  create_table "lots_parameters", force: true do |t|
    t.integer  "lot_parameter_list_id", null: false
    t.integer  "lot_parameter_type_id", null: false
    t.float    "value"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.string   "string_value"
  end

  add_index "lots_parameters", ["lot_parameter_list_id"], name: "fk_lots_parameters_lot_parameter_list_id", using: :btree
  add_index "lots_parameters", ["lot_parameter_type_id"], name: "fk_lots_parameters_lot_parameter_type_id", using: :btree

  create_table "lots_parameters_lists", force: true do |t|
    t.integer  "lot_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lots_parameters_types", force: true do |t|
    t.string   "name",                          null: false
    t.float    "default_value"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "unit"
    t.string   "code",                          null: false
    t.boolean  "is_string",     default: false
  end

  create_table "medicaments_recipes", force: true do |t|
    t.string   "code",                      null: false
    t.string   "name",                      null: false
    t.boolean  "active",     default: true
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", force: true do |t|
    t.integer  "recipe_id"
    t.integer  "client_id"
    t.integer  "user_id"
    t.integer  "product_lot_id"
    t.integer  "prog_batches",                         null: false
    t.integer  "real_batches"
    t.string   "code",                                 null: false
    t.string   "comment"
    t.boolean  "completed",            default: false
    t.boolean  "processed_in_baan",    default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "medicament_recipe_id"
    t.float    "real_production"
    t.boolean  "repaired",             default: false
    t.integer  "parameter_list_id"
    t.boolean  "auto_product_lot",     default: false
    t.boolean  "notified",             default: true
  end

  add_index "orders", ["client_id"], name: "fk_orders_client_id", using: :btree
  add_index "orders", ["code"], name: "index_orders_on_code", using: :btree
  add_index "orders", ["created_at"], name: "index_orders_on_created_at", using: :btree
  add_index "orders", ["medicament_recipe_id"], name: "fk_orders_medicament_recipe_id", using: :btree
  add_index "orders", ["parameter_list_id"], name: "fk_orders_parameter_list_id", using: :btree
  add_index "orders", ["product_lot_id"], name: "fk_orders_product_lot_id", using: :btree
  add_index "orders", ["recipe_id"], name: "fk_orders_recipe_id", using: :btree
  add_index "orders", ["user_id"], name: "fk_orders_user_id", using: :btree

  create_table "orders_areas", force: true do |t|
    t.integer  "order_id",                   null: false
    t.integer  "area_id",                    null: false
    t.boolean  "active",     default: false, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "orders_areas", ["area_id"], name: "fk_orders_areas_area_id", using: :btree
  add_index "orders_areas", ["order_id"], name: "fk_orders_areas_order_id", using: :btree

  create_table "orders_numbers", force: true do |t|
    t.string   "code",       default: "0000000001"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders_stats", force: true do |t|
    t.integer  "order_id",           null: false
    t.integer  "order_stat_type_id", null: false
    t.float    "value",              null: false
    t.integer  "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "orders_stats", ["created_at"], name: "index_orders_stats_on_created_at", using: :btree
  add_index "orders_stats", ["order_id"], name: "fk_orders_stats_order_id", using: :btree
  add_index "orders_stats", ["order_stat_type_id"], name: "fk_orders_stats_order_stat_type_id", using: :btree

  create_table "orders_stats_types", force: true do |t|
    t.string   "description",            null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.float    "min"
    t.float    "max"
    t.string   "unit",        limit: 20
    t.integer  "area_id"
    t.string   "code",                   null: false
  end

  add_index "orders_stats_types", ["area_id"], name: "fk_orders_stats_types_area_id", using: :btree

  create_table "parameters", force: true do |t|
    t.integer  "parameter_list_id"
    t.integer  "parameter_type_id"
    t.float    "value",             null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "parameters", ["parameter_list_id"], name: "fk_parameters_parameter_list_id", using: :btree
  add_index "parameters", ["parameter_type_id"], name: "fk_parameters_parameter_type_id", using: :btree

  create_table "parameters_lists", force: true do |t|
    t.string   "recipe_code",                null: false
    t.boolean  "active",      default: true
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "parameters_types", force: true do |t|
    t.string   "name",          null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.float    "default_value", null: false
  end

  create_table "pedidos_compras1", force: true do |t|
    t.string   "num_orden"
    t.integer  "num_posicion"
    t.string   "cod_material"
    t.string   "nom_material"
    t.float    "can_pedido"
    t.string   "pre_material"
    t.integer  "can_sacos"
    t.string   "cod_proveedor"
    t.string   "nom_proveedor"
    t.string   "rif_proveedor"
    t.string   "dir_proveedor"
    t.string   "tel_proveedor"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pedidos_compras2", force: true do |t|
    t.string   "num_orden"
    t.integer  "num_posicion"
    t.string   "cod_material"
    t.float    "can_bruto"
    t.float    "can_neto"
    t.float    "can_tara"
    t.string   "pla_camion"
    t.string   "ced_chofer"
    t.string   "num_almacen"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pedidos_ventas", force: true do |t|
    t.string   "tip_pedido"
    t.string   "num_pedido"
    t.integer  "pos_pedido"
    t.string   "tip_material"
    t.string   "cod_material"
    t.string   "nom_material"
    t.integer  "can_sacos"
    t.string   "pre_material"
    t.float    "pes_neto"
    t.string   "cod_cliente"
    t.string   "nom_cliente"
    t.string   "dir_cliente"
    t.string   "rif_cliente"
    t.string   "tel_cliente"
    t.string   "tip_documento"
    t.string   "num_documento"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permission_roles", force: true do |t|
    t.integer  "permission_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", force: true do |t|
    t.string   "name",       null: false
    t.string   "module",     null: false
    t.string   "action",     null: false
    t.string   "mode",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preselected_ingredients_id", force: true do |t|
    t.integer  "ingredient_id"
    t.integer  "user_id"
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.string   "report",        default: "production_and_ingredient_distribution"
  end

  create_table "preselected_recipes_codes", force: true do |t|
    t.string   "recipe_code"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "products", force: true do |t|
    t.string   "code",         null: false
    t.string   "name",         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "base_unit_id"
  end

  create_table "products_lots", force: true do |t|
    t.integer  "product_id"
    t.string   "code",                                               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "client_id"
    t.boolean  "active",                              default: true
    t.decimal  "stock",      precision: 15, scale: 4, default: 0.0,  null: false
    t.string   "comment"
    t.boolean  "in_use",                              default: true
  end

  add_index "products_lots", ["product_id"], name: "fk_products_lots_product_id", using: :btree

  create_table "products_lots_parameters", force: true do |t|
    t.integer  "product_lot_parameter_list_id", null: false
    t.integer  "product_lot_parameter_type_id", null: false
    t.float    "value"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "string_value"
  end

  add_index "products_lots_parameters", ["product_lot_parameter_list_id"], name: "fk_products_lots_parameters_product_lot_parameter_list_id", using: :btree
  add_index "products_lots_parameters", ["product_lot_parameter_type_id"], name: "fk_products_lots_parameters_product_lot_parameter_type_id", using: :btree

  create_table "products_lots_parameters_lists", force: true do |t|
    t.integer  "product_lot_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "products_lots_parameters_types", force: true do |t|
    t.string   "name",                          null: false
    t.float    "default_value"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "unit"
    t.string   "code",                          null: false
    t.boolean  "is_string",     default: false
  end

  create_table "products_parameters_types_ranges", force: true do |t|
    t.integer  "product_id",                    null: false
    t.integer  "product_lot_parameter_type_id", null: false
    t.float    "max"
    t.float    "min"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "products_parameters_types_ranges", ["product_id"], name: "fk_product_id", using: :btree
  add_index "products_parameters_types_ranges", ["product_lot_parameter_type_id"], name: "fk_product_lot_parameter_type_id", using: :btree

  create_table "purchases_order", force: true do |t|
    t.string   "code"
    t.integer  "id_client"
    t.boolean  "closed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "purchases_order_items", force: true do |t|
    t.integer  "id_purchase_order"
    t.integer  "id_ingredient"
    t.integer  "position"
    t.integer  "quantity"
    t.boolean  "sack"
    t.float    "total_weight"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recipes", force: true do |t|
    t.string   "code"
    t.string   "name",                                 null: false
    t.string   "version"
    t.float    "total",                default: 0.0
    t.boolean  "active",               default: true
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "in_use",               default: true
    t.integer  "product_id",                           null: false
    t.boolean  "internal_consumption", default: false
    t.integer  "type_id",              default: 0
  end

  add_index "recipes", ["product_id"], name: "index_recipes_on_product_id", using: :btree
  add_index "recipes", ["type_id"], name: "index_recipes_on_type_id", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name",        null: false
    t.string   "description", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scales", force: true do |t|
    t.string   "name",                           null: false
    t.float    "maximum_weight"
    t.float    "minimum_weight"
    t.boolean  "not_weighed",    default: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "schedules", force: true do |t|
    t.string   "name"
    t.time     "start_hour"
    t.time     "end_hour"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "settings", force: true do |t|
    t.float    "hopper_minimum_level",  default: 10.0, null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.float    "ticket_reception_diff", default: 0.5
    t.float    "ticket_dispatch_diff",  default: 0.5
  end

  create_table "tickets", force: true do |t|
    t.integer  "truck_id"
    t.integer  "driver_id"
    t.integer  "number"
    t.boolean  "open",                     default: true
    t.float    "incoming_weight"
    t.float    "outgoing_weight"
    t.float    "provider_weight"
    t.string   "provider_document_number"
    t.datetime "incoming_date"
    t.datetime "outgoing_date"
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ticket_type_id"
    t.integer  "user_id"
    t.integer  "client_id"
    t.boolean  "manual_incoming",          default: false
    t.boolean  "manual_outgoing",          default: false
    t.boolean  "repaired",                 default: false, null: false
    t.boolean  "notified",                 default: true
    t.string   "address"
    t.integer  "document_type_id"
  end

  add_index "tickets", ["client_id"], name: "fk_tickets_client_id", using: :btree
  add_index "tickets", ["driver_id"], name: "fk_tickets_driver_id", using: :btree
  add_index "tickets", ["driver_id"], name: "index_tickets_on_driver_id", using: :btree
  add_index "tickets", ["truck_id"], name: "fk_tickets_truck_id", using: :btree
  add_index "tickets", ["user_id"], name: "fk_tickets_user_id", using: :btree

  create_table "tickets_numbers", force: true do |t|
    t.string   "number",     default: "0000000001"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tickets_types", force: true do |t|
    t.string   "code",        null: false
    t.string   "description", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transaction_types", force: true do |t|
    t.string   "code",        null: false
    t.string   "description", null: false
    t.string   "sign",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: true do |t|
    t.integer  "transaction_type_id",                                          null: false
    t.integer  "user_id",                                                      null: false
    t.float    "amount",                                                       null: false
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "processed_in_stock",                           default: 0
    t.integer  "client_id"
    t.integer  "ticket_id"
    t.boolean  "sack",                                         default: false
    t.float    "sack_weight"
    t.integer  "sacks"
    t.string   "document_number"
    t.decimal  "stock_after",         precision: 15, scale: 4
    t.integer  "content_id",                                                   null: false
    t.integer  "content_type",                                                 null: false
    t.integer  "order_id"
    t.boolean  "notified",                                     default: true
  end

  add_index "transactions", ["content_id"], name: "index_transactions_on_content_id", using: :btree
  add_index "transactions", ["content_type"], name: "index_transactions_on_content_type", using: :btree
  add_index "transactions", ["created_at"], name: "index_transactions_on_created_at", using: :btree
  add_index "transactions", ["order_id"], name: "index_transactions_on_order_id", using: :btree
  add_index "transactions", ["ticket_id"], name: "index_transactions_on_ticket_id", using: :btree

  create_table "trucks", force: true do |t|
    t.integer  "carrier_id"
    t.string   "license_plate",                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "frequent",      default: true
  end

  add_index "trucks", ["carrier_id"], name: "fk_trucks_carrier_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "name",                          null: false
    t.string   "login",                         null: false
    t.string   "password_hash",                 null: false
    t.string   "password_salt",                 null: false
    t.boolean  "admin",         default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id"
  end

  create_table "warehouses", force: true do |t|
    t.integer  "ingredient_id"
    t.integer  "warehouse_type_id"
    t.string   "code",                            null: false
    t.string   "name",                            null: false
    t.float    "stock",             default: 0.0
    t.string   "location",                        null: false
    t.float    "size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "warehouses", ["ingredient_id"], name: "index_warehouses_on_ingredient_id", using: :btree
  add_index "warehouses", ["warehouse_type_id"], name: "index_warehouses_on_warehouse_type_id", using: :btree

  create_table "warehouses_types", force: true do |t|
    t.string   "code",        null: false
    t.string   "description", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
