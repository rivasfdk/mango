class AddCommentToProductLots < ActiveRecord::Migration
  def change
  	add_column :products_lots, :comment, :string
  end
end
