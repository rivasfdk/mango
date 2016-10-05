namespace :seed_generate do

  desc "Export seeds from database"
  task load_seeds: :environment do
  Permission.order(:id).all.each do |permission|
puts "Permission.create(#{permission.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  Role.order(:id).all.each do |role|
puts "Role.create(#{role.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  PermissionRole.order(:id).all.each do |permission_role|
puts "PermissionRole.create(#{permission_role.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  BaseUnit.order(:id).all.each do |base_unit|
puts "BaseUnit.create(#{base_unit.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  DocumentType.order(:id).all.each do |document_type|
puts "DocumentType.create(#{document_type.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  HopperLotTransactionType.order(:id).all.each do |hlt_type|
puts "HopperLotTransactionType.create(#{hlt_type.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  OrderNumber.order(:id).all.each do |order_number|
puts "OrderNumber.create(#{order_number.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  Settings.order(:id).all.each do |setting|
puts "Settings.create(#{setting.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  TicketNumber.order(:id).all.each do |ticketNumber|
puts "TicketNumber.create(#{ticketNumber.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  TicketType.order(:id).all.each do |ticket_type|
puts "TicketType.create(#{ticket_type.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
  TransactionType.order(:id).all.each do |transaction_type|
puts "TransactionType.create(#{transaction_type.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end

end

end