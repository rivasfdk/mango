class ChangeDiffautorizeToBeIntegerInTickets < ActiveRecord::Migration
  def change
    change_column :tickets, :diff_authorized, :integer
  end
end
