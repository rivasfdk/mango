class AddPriorityToHoppers < ActiveRecord::Migration
  def change
    add_column :hoppers, :priority, :integer
    Hopper.find_each do |hopper|
      hopper.priority = hopper.number
      hopper.save!(:validate => false)
    end
  end
end
