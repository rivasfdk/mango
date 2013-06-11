Mango::Application.routes.draw do

  match 'ingredients/search' => "ingredients#search", :via => :get, :as => 'ingredient_search'
  match 'ingredients/catalog' => "ingredients#catalog", :via => :get, :as => 'ingredient_catalog'
  match 'ingredients/select' => "ingredients#select", :via => :get, :as => 'ingredient_select'
  match 'recipes/:id/clone' => "recipes#clone", :via => :get, :as => 'clone_recipe'
  match 'recipes/import' => "recipes#import", :via => :get, :as => 'recipe_import'
  match 'recipes/upload' => "recipes#upload", :via => :post, :as => 'recipe_upload'
  match 'recipes/:id/create_parameter_list' => "recipes#create_parameter_list", :via => :get, :as => 'recipe_create_parameter_list'
  match 'recipes/:id/deactivate' => "recipes#deactivate", :via => :get, :as => 'deactivate_recipe'
  match 'warehouses/recalculate' => "warehouses#recalculate", :via => :get, :as => 'recalculate_warehouses'
  match 'transactions/reprocess' => "transactions#reprocess", :via => :get, :as => 'reprocess_transactions'
  match 'transactions/export' => "transactions#export", :via => :get, :as => 'export_transactions'
  match 'transactions/download' => "transactions#download", :via => :get, :as => 'download_transactions'
  match 'roles/:id/clone' => "roles#clone", :via => :get, :as => 'clone_role'
  match 'tickets/:id/print' => "tickets#print", :via => :get, :as => 'print_ticket'
  match 'orders/:id/repair' => "orders#repair", :via => :get, :as => 'repair_order'
  match 'orders/:id/repair' => "orders#do_repair", :via => :put, :as => 'repair_order'
  match 'orders/:id/print' => "orders#print", :via => :get, :as => 'print_order'
  match 'orders/:id/generate_transactions' => "orders#generate_transactions", :via => :put, :as => 'generate_transactions_order'
  match 'sessions/not_implemented' => "sessions#not_implemented", :via => :get, :as => "not_implemented"
  match 'lots/:id/adjust' => "lots#adjust", :via => :get, :as => 'adjust_lot'
  match 'lots/:id/adjust' => "lots#do_adjust", :via => :put, :as => 'adjust_lot'
  match 'product_lots/:id/adjust' => "product_lots#adjust", :via => :get, :as => 'adjust_product_lot'
  match 'product_lots/:id/adjust' => "product_lots#do_adjust", :via => :put, :as => 'adjust_product_lot'
  match 'sessions/not_implemented' => "sessions#not_implemented", :via => :get, :as => "not_implemented"
  match 'parameter_lists/:id/clone' => "parameter_lists#clone", :via => :get, :as => "parameter_list_clone"
  # Reports
  match 'reports' => "reports#index", :via => :get, :as => "reports"
  match 'reports/recipes' => "reports#recipes", :via => :post, :as => "recipes_report"
  match 'reports/daily_production' => "reports#daily_production", :via => :post, :as => "daily_production_report"
  match 'reports/real_production' => "reports#real_production", :via => :post, :as => "real_production_report"
  match 'reports/order_duration' => "reports#order_duration", :via => :post, :as => "order_duration_report"
  match 'reports/order_details' => "reports#order_details", :via => :post, :as => "order_details_report"
  match 'reports/batch_details' => "reports#batch_details", :via => :post, :as => "batch_details_report"
  match 'reports/consumption_per_recipe' => "reports#consumption_per_recipe", :via => :post, :as => "consumption_per_recipe_report"
  match 'reports/consumption_per_selected_ingredients' => "reports#consumption_per_selected_ingredients", :via => :post, :as => "consumption_per_selected_ingredients_report"
  match 'reports/consumption_per_ingredients' => "reports#consumption_per_ingredients", :via => :post, :as => "consumption_per_ingredients_report"
  match 'reports/consumption_per_ingredient_per_orders' => "reports#consumption_per_ingredient_per_orders", :via => :post, :as => "consumption_per_ingredient_per_orders_report"
  match 'reports/consumption_per_client' => "reports#consumption_per_client", :via => :post, :as => "consumption_per_client_report"
  match 'reports/stock_adjustments' => "reports#stock_adjustments", :via => :post, :as => "stock_adjustments_report"
  match 'reports/lots_incomes' => "reports#lots_incomes", :via => :post, :as => "lots_incomes_report"
  match 'reports/simple_stock' => "reports#simple_stock", :via => :post, :as => "simple_stock_report"
  match 'reports/ingredients_stock' => "reports#ingredients_stock", :via => :post, :as => "ingredients_stock_report"
  match 'reports/products_stock' => "reports#products_stock", :via => :post, :as => "products_stock_report"
  match 'reports/product_lots_dispatches' => "reports#product_lots_dispatches", :via => :post, :as => "product_lots_dispatches_report"
  match 'reports/tickets_transactions' => "reports#tickets_transactions", :via => :post, :as => "tickets_transactions_report"
  match 'reports/tickets_transactions_per_clients' => "reports#tickets_transactions_per_clients", :via => :post, :as => "tickets_transactions_per_clients_report"
  match 'reports/tickets_transactions_per_contents' => "reports#tickets_transactions_per_contents", :via => :post, :as => "tickets_transactions_per_contents_report"
  match 'reports/tickets_transactions_per_contents_per_clients' => "reports#tickets_transactions_per_contents_per_clients", :via => :post, :as => "tickets_transactions_per_contents_per_clients_report"
  match 'reports/tickets_transactions_per_carrier' => "reports#tickets_transactions_per_carrier", :via => :post, :as => "tickets_transactions_per_carrier_report"
  match 'reports/tickets_transactions_per_driver' => "reports#tickets_transactions_per_driver", :via => :post, :as => "tickets_transactions_per_driver_report"
  match 'reports/production_per_recipe' => "reports#production_per_recipe", :via => :post, :as => "production_per_recipe_report"
  match 'reports/production_per_client' => "reports#production_per_client", :via => :post, :as => "production_per_client_report"
  match 'reports/alarms' => "reports#alarms", :via => :post, :as => "alarms_report"
  match 'reports/alarms_per_order' => "reports#alarms_per_order", :via => :post, :as => "alarms_per_order_report"
  match 'batches/:batch_id/batches_hopper_lot' => "batches_hopper_lot#create", :via => :post, :as => "batches_hopper_lot"
  match 'batches/:batch_id/batches_hopper_lot/:id' => "batches_hopper_lot#destroy", :via => :delete, :as => "batch_hopper_lot"
  resources :sessions, :users, :ingredients, :clients, :factories, :hoppers, :products, :orders, :lots, :schedules, :batches,
    :transaction_types, :product_lots, :permissions, :drivers, :carriers, :trucks, :mixing_times, :alarm_types, :parameter_types
  resources :transactions, :except=>:edit
  resources :tickets, :except=>:edit

  resources :recipes do
    resources :ingredients_recipes
  end

  resources :medicament_recipes do
    resources :ingredients_medicament_recipes
  end

  resources :parameter_lists do
    resources :parameters
  end

  resources :roles do
    resources :permissions_roles
  end

  root :to => "sessions#index"

  match "/sessions/show" => "sessions#show"
end
