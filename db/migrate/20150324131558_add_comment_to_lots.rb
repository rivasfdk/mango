class AddCommentToLots < ActiveRecord::Migration
  def change
  	add_column :lots, :comment, :string
  end
end
