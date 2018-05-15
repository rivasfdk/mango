class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.integer :type_id
      t.integer :user_id
      t.string :action

      t.timestamps
    end
  end
end
