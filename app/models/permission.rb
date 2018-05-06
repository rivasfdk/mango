class Permission < ActiveRecord::Base
  attr_protected :id

  has_many :permission_role

  after_save :associate_role
  after_destroy :deassociate_role

  validates :name, :module, :action, :mode, presence: true

  MODULES = ['batches', 'orders', 'recipes', 'hoppers', 'batches_hopper_lot', 'transactions', 'lots',
    'product_lots', 'ingredients', 'ingredients_recipes', 'products', 'clients', 'factories', 'transaction_types',
    'schedules', 'users', 'roles', 'permissions', 'reports', 'medicament_recipes', 'drivers', 'carriers',
    'trucks', 'tickets', 'alarm_types', 'parameters', 'parameter_types', 'parameter_lists', 'scales',
    'lot_parameters', 'lot_parameter_types', 'lot_parameter_lists', 'settings', 'product_lot_parameters',
    'product_lot_parameter_types', 'product_lot_parameter_lists', 'warehouse_types', 'warehouses', 'locations', 'machines']
  # Permission actions
  ACTIONS = ['consult', 'modify', 'delete', 'create']
  MODES = ['global', 'module']

  # Rails actions
  CONSULT = ['index', 'show', 'print', 'lots', 'by_recipe', 'get_all', 'all', 'get_all_reception',
            'get_all_dispatch', 'get_order_client','get_item_warehouse', 'get_client']
  MODIFY = ['edit', 'update', 'clone', 'adjust', 'do_adjust', 'deactivate', 'set_as_main_hopper',
           'create_order_stat', 'fill', 'do_fill', 'change', 'do_change', 'change_ingredient',
           'do_change_ingredient', 'change_product', 'do_change_product']
  DELETE = ['destroy']
  CREATE = ['new', 'create','import', 'items', 'update_items', 'entry', 'update_entry', 'close',
           'do_close', 'get_server_romano_ip', 'get_client']

  def self.get_modules
    MODULES
  end

  def self.get_actions
    ACTIONS
  end

  def self.get_modes
    MODES
  end

  def self.is_consult?(action)
    CONSULT.include?(action)
  end

  def self.is_modify?(action)
    MODIFY.include?(action)
  end

  def self.is_delete?(action)
    DELETE.include?(action)
  end

  def self.is_create?(action)
    CREATE.include?(action)
  end

  def self.is_recalculate?(action)
    return action == 'recalculate'
  end

  def self.is_import?(action)
    return (action == 'import' or action == 'upload')
  end

  def self.is_reprocess?(action)
    return action == 'reprocess'
  end

  def self.is_repair?(action)
    return (action == 'repair' or action == 'do_repair')
  end

  def self.is_change?(action)
    return (action == 'change' or action == 'do_change' or action == 'change_factory_lots' or action == 'do_change_factory_lots')
  end

  def self.is_fill?(action)
    return (action == 'fill' or action == 'do_fill')
  end

  def self.is_adjust?(action)
    return (action == 'adjust' or action == 'do_adjust')
  end

  def self.is_notify?(action)
    return (action == 'notify' or action == 'do_notify')
  end

  def self.is_print_recipe?(action)
    return (action == 'print_recipe')
  end

  def self.is_manual?(action)
    return (action == 'manual')
  end

  def self.is_authorized?(action)
    return (action == 'authorized')
  end

  def self.is_stock?(action)
    return (action == 'stock')
  end

  def self.get_all
    find :all, :order => 'module ASC, name ASC'
  end

  def self.generate_globals(controller, actions)
    failed = []
    actions.each do |action|
      p = Permission.where({:module => controller, :action => action,
                           :mode => "global"}).first
      name = "#{controller.capitalize} #{action}"
      if p.nil?
        logger.debug("Generating permission: #{name}")
        p = Permission.new
        p.name = name
        p.module = controller
        p.action = action
        p.mode = "global"
        p.save
      else
        failed << action
        logger.debug("Permission: #{name} already exists")
      end
    end
    failed
  end

  private

  def associate_role
    pr = PermissionRole.create({:permission_id=>self.id, :role_id=>1})
  end

  def deassociate_role
    PermissionRole.delete_all :permission_id=>self.id
  end
end
