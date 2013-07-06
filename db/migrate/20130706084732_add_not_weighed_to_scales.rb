class AddNotWeighedToScales < ActiveRecord::Migration
  def change
    add_column :scales, :not_weighed, :boolean, :default => false
  end
end
