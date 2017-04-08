class User < ActiveRecord::Base
  has_many :order, inverse_of: :user
  has_many :batch
  has_many :transaction
  has_many :tickets
  has_many :preselected_recipes_codes
  belongs_to :role

  validates_uniqueness_of :login
  validates_presence_of :name, :login, :role
  validates_length_of :name, :login, :within => 3..40

  before_save :validate_password

  attr_accessor :password, :password_confirmation
  attr_protected :id, :password_salt

  def self.auth(login, password)
    user = User.includes(:role).where(["login = ?", login]).first
    return nil if user.nil?
    return user if User.encrypt(password, user.password_salt) == user.password_hash
    return nil
  end

  def allow_manual
    return true if self.role_id == 1
    self.role.permissions.where({:module => "tickets", :action => "manual"}).any?
  end

  def get_dashboard_permissions
    permissions = []

    # You shall not question my god.
    if self.role_id == 1 # Sure there is a better way
      perm = PermissionRole.includes(:permission).where({:permissions=>{:action=>'consult'}})
    else
      perm = PermissionRole.includes(:permission).where({:role_id=>self.role_id, :permissions=>{:action=>'consult'}})
    end

    perm.each do |pr|
      permissions << pr.permission.module unless permissions.include? pr.permission.module
    end
    return permissions
  end

  def password=(pass)
    return if pass.blank?
    @password = pass
    self.password_salt = User.generate_salt if !self.password_salt?
    self.password_hash = User.encrypt(pass, self.password_salt)
  end

  def get_reports_permissions
    report_permissions = []
    if self.role_id == 1 # It's even nastier than I thought
      perm = PermissionRole.includes(:permission).where({:permissions=>{:module=>'reports'}})
    else
      perm = PermissionRole.includes(:permission).where({:role_id=>self.role_id, :permissions=>{:module=>'reports'}})
    end

    perm.each do |p|
      report_permissions << p.permission.action unless report_permissions.include? p.permission.action
    end
    return report_permissions
  end

  def get_reports_permissions_fdk
    # ADD CODE HERE
  end

  def has_global_permission?(controller, action)
    return true if self.role_id == 1 # Admin

    valid = false
    permission_roles = PermissionRole.find_with_permissions(self.role_id, controller, 'global')
    logger.debug "GLOBAL::action: #{action} - controller: #{controller}"
    puts permission_roles.inspect
    permission_roles.each do |pm|
      if pm.permission.action == 'consult' and Permission.is_consult?(action)
        valid = true
      elsif pm.permission.action == 'modify' and Permission.is_modify?(action)
        valid = true
      elsif pm.permission.action == 'delete' and Permission.is_delete?(action)
        valid = true
      elsif pm.permission.action == 'create' and Permission.is_create?(action)
        valid = true
      elsif pm.permission.action == 'import' and Permission.is_import?(action)
        valid = true
      elsif pm.permission.action == 'repair' and Permission.is_repair?(action)
        valid = true
      elsif pm.permission.action == 'adjust' and Permission.is_adjust?(action)
        valid = true
      elsif pm.permission.action == 'change' and Permission.is_change?(action)
        valid = true
      elsif pm.permission.action == 'fill' and Permission.is_fill?(action)
        valid = true
      elsif pm.permission.action == 'notify' and Permission.is_notify?(action)
        valid = true
      elsif pm.permission.action == 'print_recipe' and Permission.is_print_recipe?(action)
        valid = true
      elsif pm.permission.action == action
        valid = true
      end
      return true if valid
    end
    return false
  end

  def has_module_permission?(controller, action)
    return true if self.role_id == 1 # You should be able to see it by now Mr. Anderson

    permission_roles = PermissionRole.find_with_permissions(self.role_id, controller, 'module')
    permission_roles.each do |pm|
      puts "MODULE::action: #{action} - controller: #{controller}"
      puts "MODULE::permission.action: #{pm.permission.action} - permission.module: #{pm.permission.module}"
      return true if pm.permission.action == action
    end
    return false
  end

  private

  def validate_password
    return true if @password.blank? and @password_confirmation.blank? and !self.new_record?
    errors.add(:password, "can't be blank") if @password.blank?
    errors.add(:password, "is too short (minimum is 5 characters)") if !@password.nil? and @password.length < 5
    errors.add(:password_confirmation, "can't be blank") if @password_confirmation.blank?
    errors.add(:password_confirmation, "doesn't match") if @password != @password_confirmation
    return false if errors.size > 0
  end

  protected

  def self.encrypt(pass, salt)
    return Digest::SHA256.hexdigest(pass + salt)
  end

  def self.generate_salt
    return [Array.new(6){rand(256).chr}.join].pack("m").chomp
  end

end
