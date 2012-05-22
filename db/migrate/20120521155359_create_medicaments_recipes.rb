class CreateMedicamentsRecipes < ActiveRecord::Migration
  def self.up
    create_table :medicaments_recipes do |t|
      t.string :code, :null => false
      t.string :name, :null => false
      t.boolean :active, :default => true
      t.text :comment
      t.timestamps
    end
  end

  def self.down
    drop_table :medicaments_recipes
  end
end
