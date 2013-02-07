class UpdateContentIdContentTypeInTransactions < ActiveRecord::Migration
  def self.up
    Transaction.all.each do |t|
      unless t.warehouse.nil?
        puts t.id
        t.content_id = t.warehouse.content_id
        t.content_type = t.warehouse.warehouse_type_id
        t.save
      end
    end
  end

  def self.down
  end
end
