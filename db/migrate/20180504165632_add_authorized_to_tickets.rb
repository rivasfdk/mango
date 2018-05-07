class AddAuthorizedToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :diff_authorized, :bool
    add_column :tickets, :authorized_user_id, :integer
  end
end
