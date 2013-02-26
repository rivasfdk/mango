class UpdateContentIdContentTypeInTransactions < ActiveRecord::Migration
  def self.up
    Transaction.all.each do |t|
      warehouse_query = "SELECT * FROM warehouses WHERE id = #{t.warehouse_id} LIMIT 1"
      warehouse = ActiveRecord::Base.connection.select_one(warehouse_query)
      if warehouse.nil?
        next
      end
      t.content_id = warehouse['content_id']
      t.content_type = warehouse['warehouse_type_id']
      t.save
    end
  end

  def self.down
  end
end
