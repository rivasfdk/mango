# encoding: UTF-8

class Recipe < ActiveRecord::Base
  TYPES = {
    0 => 'Ninguno',
    1 => 'Pre Iniciador Pollos',
    2 => 'Pollonas (F1)',
    3 => 'Pollonas (F2)',
    4 => 'Pre Postura',
    5 => 'Postura 19%',
    6 => 'Postura 17%',
    7 => 'Maquila',
    8 => 'Equinos',
    9 => 'Cerdos',
    10 => 'Vacunos',
  }

  has_many :ingredient_recipe, dependent: :destroy
  has_many :order
  belongs_to :product

  accepts_nested_attributes_for :ingredient_recipe, allow_destroy: true, reject_if: lambda { |ir| t[:ingredient_id].blank? }

  validates :name, :code, :product, presence: true
  validates :name, length: {within: 3..40}

  before_save :update_all_versions, if: :internal_consumption_changed?
  before_save :update_all_types, if: :type_id_changed?

  def update_all_versions
    Recipe
      .where(code: self.code)
      .update_all(internal_consumption: self.internal_consumption)
  end

  def update_all_types
    Recipe
      .where(code: self.code)
      .update_all(type_id: self.type_id)
  end

  def add_ingredient(args)
    logger.debug("Agregando ingrediente: #{args.inspect}")
    overwrite = args[:overwrite]
    icode = args[:ingredient].split(' ')[0]
    iname = args[:ingredient][(icode.length + 1)..args[:ingredient].length].strip()
    ingredient = Ingredient.find_by_code(icode)
    if ingredient.nil?
      logger.debug("  - El ingrediente no existe. Se crea")
      ingredient = Ingredient.create code: icode, name: iname
    end
    item = IngredientRecipe.where(ingredient_id: ingredient.id, recipe_id: self.id).first
    if item.nil?
      item = IngredientRecipe.new
      item.ingredient_id = ingredient.id
      item.amount = args[:amount]
      item.priority = args[:priority]
      item.percentage = args[:percentage]
      self.ingredient_recipe << item
    else
      item.amount = args[:amount]
      item.priority = args[:priority]
      item.percentage = args[:percentage]
      item.save if overwrite
    end
    logger.debug("Ingrediente agregado: #{item.inspect}")
  end

  def validate
    hopper_ingredients = []
    hopper_lots = HopperLot.where(active: true)
    hopper_lots.each do |hl|
      hopper_ingredients << hl.lot.ingredient.id
    end
    valid = true
    self.ingredient_recipe.each do |ir|
      unless hopper_ingredients.include? ir.ingredient.id
        valid = false
        break
      end
    end
    return valid
  end

  def import(filepath, overwrite)
    begin
      transaction do
        file_total = 0
        file_imported = 0
        fd = File.open(filepath, 'r')
        continue = fd.gets().split(';')
        while (continue)
          file_total += 1
          header = continue
          return false unless validate_field(header[0], 'C')
          version = header[1]
          code = header[2]
          name = header[3].strip()
          total = header[5]

          @previously_stored_recipe = Recipe.where(code: code, version: version).first
          unless @previously_stored_recipe.nil?
            logger.debug("Receta: #{@previously_stored_recipe.code} version #{@previously_stored_recipe.version} ya existe")
            unless @previously_stored_recipe.active
              file_imported += 1
              @current_active_recipe = Recipe.where(code: header[2], active: true).first
              unless @current_active_recipe.nil?
                @current_active_recipe.active = false
                @current_active_recipe.save
              end
              @previously_stored_recipe.active = true
              @previously_stored_recipe.save
            end
            while (true)
              item = fd.gets()
              break if item.nil?
              item = item.split(';')
              break if item.length == 1
            end
          else
            @previous_version_recipe = Recipe.where(code: header[2], active: true).first
            internal_consumption = false
            unless @previous_version_recipe.nil?
              internal_consumption = @previous_version_recipe.internal_consumption
              @previous_version_recipe.active = false
              @previous_version_recipe.save
            end
            file_imported += 1
            @recipe = Recipe.new(
              code: header[2],
              name: header[3].strip(),
              version: header[1],
              internal_consumption: internal_consumption
            )
            logger.debug("Creando encabezado de receta #{@recipe.inspect}")
            while (true)
              item = fd.gets()
              break if item.nil?
              item = item.split(';')
              logger.debug("  * Ingrediente: #{item.inspect}")
              break if item.length == 1
              return false unless validate_field(item[0], 'D')
              @recipe.add_ingredient(
                amount: item[3].to_f,
                priority: item[1].to_i,
                percentage: 0,
                ingredient: item[2],
                overwrite: overwrite
              )
            end
            @recipe.total = total.to_f
            @recipe.product_id = Product.first.id
            @recipe.save
          end
          continue = fd.gets()
          break if continue.nil?
          continue = continue.split(';')
        end
        @last_imported_recipe = LastImportedRecipe.last
        @last_imported_recipe.imported_recipes = file_imported
        @last_imported_recipe.total_recipes = file_total
        @last_imported_recipe.save

      end
    rescue Exception => ex
      errors.add(:unknown, ex.message)
      return false
    end
    return true
  end

  def get_total
    self.ingredient_recipe.sum(:amount).round(2)
  end

  def to_collection_select
    return "#{self.code} - #{self.name} - V#{self.version}"
  end

  def to_collection_select_code
    return "#{self.code} - #{self.name}"
  end

  def deactivate
    self.active = false
    self.save
  end

  private

  def validate_field(field, value)
    field.strip!()
    if field != value
      errors.add(:upload_file, "Archivo inválido")
      return false
    end
    return true
  end

  def validate_starts_with(field, value)
    field.strip!()
    unless field.start_with?(value)
      errors.add(:upload_file, "Archivo inválido")
      return false
    end
    return true
  end

  def convert_to_float(string)
    value = string.strip().gsub('.', '')
    value = value.gsub(',', '.')
    value.to_f
  end

  def self.search(params)
    @recipes = Recipe.order("created_at asc")
    @recipes = @recipes.where(active: true)
    @recipes = @recipes.where(code: params[:code]) if params[:code].present?
    @recipes.paginate page: params[:page], per_page: params[:per_page]
  end
end
