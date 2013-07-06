include MigrationHelper

class AddScaleIdToHoppers < ActiveRecord::Migration
  def up
    add_column :hoppers, :scale_id, :integer
    unless Hopper.first.nil?
      default_scale = Scale.first
      if default_scale.nil?
        default_scale = Scale.new name: "Balanza predeterminada", minimum_weight: 0, maximum_weight: 100
        default_scale.save
      end
      Hopper.all.each do |h|
        h.scale_id = default_scale.id
        h.save
      end
    end
    change_column :hoppers, :scale_id, :integer, :null => false
    add_foreign_key :hoppers, 'scale_id', :scales
  end

  def down
    drop_foreign_key :hoppers, 'scale_id'
    remove_column :hoppers, :scale_id
  end
end
