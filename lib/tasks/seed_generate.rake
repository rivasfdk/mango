namespace :seed_generate1 do

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
  User.order(:id).all.each do |user|
puts "User.create(#{user.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include? (key)}.to_s.gsub(/[{}]/,'')})"
  end
end

end