class AddEnableCreateToTicketsNumbers < ActiveRecord::Migration
  def change
    add_column :tickets_numbers, :enable_create, :bool
  end
end
