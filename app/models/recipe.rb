class Recipe < ActiveRecord::Base
  has_many :ingredient_recipe
  
  # validates_uniqueness_of :code
  validates_presence_of :name, :version, :total #, :code
  validates_length_of :name, :within => 3..40 #, :code
  validates_numericality_of :total
  
  def self.import(upload)
    begin
      name =  upload['datafile'].original_filename
      directory = "public/data"
      # create the file path
      filepath = File.join(directory, name)
      # write the file
      File.open(path, "wb") { |f| f.write(upload['datafile'].read) }

      fd = File.open(filepath, 'r')
      continue = fd.gets()
      while (continue)
        0.upto(7) { |i| fd.gets() }
        header = fd.gets().split(/\t/)
        @recipe = Recipe.new
        @recipe.version = header[0]
        @recipe.name = header[1]
        #@date = header[2]
        fd.gets()
        while (true)
          item = fd.gets().split(/\t/)
          break if item[0].strip() == '-----------'
          recipe_item = IngredientRecipe.new :amount=>item[0].to_f, :priority=>item[1].to_i, :percentage=>item[3].strip().to_f
          recipe_item.ingredient = Ingredient.find_by_code(item[2].split(' ')[0])
          @recipe.ingredient_recipe << recipe_item
        end
        @recipe.total = fd.gets().strip().to_f
        @recipe.save
        puts @recipe.inspect, @recipe.errors.inspect
        continue = fd.gets().strip()
        break if continue.nil? or continue == '='
      end
    rescue => err
      puts "Exception: #{err}"
      return false
    end
  end
end
