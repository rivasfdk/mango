class Hopper < ActiveRecord::Base
  belongs_to :scale
  has_many :hopper_lot
  validates_uniqueness_of :number, :scope => :scale_id
  validates_presence_of :number, :name, :scale
  validates_numericality_of :number, :only_integer => true, :greater_than_or_equal_to => 0

  def current_lot
    hopper_lot = HopperLot.find :first,
                                :include => :lot,
                                :conditions => ['hopper_id = ? and active = ?', self.id, true]
    return hopper_lot.nil? ? nil : hopper_lot.lot
  end

  def set_as_main_hopper
    hoppers = Hopper.find :all,
                          :include => {:hopper_lot => :lot},
                          :conditions => ['hoppers.id != ? and hoppers_lots.active = true and lots.ingredient_id = ?', self.id, self.current_lot.ingredient_id]
    unless hoppers.empty?
      Hopper.update_all('main = false', :id => hoppers.map {|hopper| hopper.id})
    end
    self.update_attributes(:main => true)
  end

  def eliminate
    begin
      b = BatchHopperLot.find :all,
                              :include => [:hopper_lot],
                              :conditions => {:hoppers_lots => {:hopper_id => self.id}}
      if b.length > 0
        errors.add(:foreign_key, 'no se puede eliminar porque tiene registros asociados')
        return
      end

      #If there is no main hopper for the hopper ingredient after deleting the hopper
      #set hopper.main to true to the first hopper with the ingredient (if any)
      current_hopper_lot = HopperLot.find :first,
                                          :include => [:lot],
                                          :conditions => ['active = true and hopper_id = ?', self.id]
      hoppers = Hopper.find :all,
                            :include => {:hopper_lot => [:lot]},
                            :conditions => ['hoppers.id != ? and hoppers_lots.active = true and lots.ingredient_id = ?', self.id, current_hopper_lot.lot.ingredient_id],
                            :order => ['hoppers.scale_id, hoppers.number ASC']
      unless hoppers.empty?
        if hoppers.select {|hopper| hopper.main == true}.empty?
          hoppers.first.main = true
          hoppers.first.save
        end
      end

      self.hopper_lot.each do |i|
        i.destroy
      end
      self.destroy
    rescue ActiveRecord::StatementInvalid => ex
      puts ex.inspect
      errors.add(:foreign_key, 'no se puede eliminar porque tiene registros asociados')
    rescue Exception => ex
      errors.add(:unknown, ex.message)
    end
  end


  def self.find_actives(scale_id)
    actives = []
    hoppers_lots = HopperLot.find :all,
                                  :include => {:hopper => {}, :lot => {:ingredient => {}}}, 
                                  :conditions => {:active => true, :hoppers => {:scale_id => scale_id}},
                                  :order => ['hoppers.number ASC']
    hoppers_lots.each do |hl|
      actives << {
        :lot => hl,
        :hopper_id => hl.hopper_id,
        :number => hl.hopper.number,
        :name => hl.hopper.name,
        :main => hl.hopper.main,
      }
    end
    return actives
  end

  def self.actives_to_select
    actives = []
    hoppers_lots = HopperLot.find :all,
                                  :include => {:hopper => {}, :lot => {:ingredient => {}}},
                                  :conditions => {:active => true},
                                  :order => ['hoppers.scale_id, hoppers.number ASC']
    hoppers_lots.each do |hl|
      name = hl.hopper.name.present? ? hl.hopper.name : hl.hopper.number
      actives << ["Tolva #{name} - #{hl.lot.ingredient.name} (L: #{hl.lot.code})", hl.id]
    end
    return actives
  end

  def self.set_main_hoppers
    Hopper.update_all('main = false')
    main_hoppers = {}
    hoppers_lots = HopperLot.find :all,
                                  :include => {:hopper => {}, :lot => {}},
                                  :conditions => {:active => true},
                                  :order => ['hoppers.scale_id, hoppers.number ASC']
    hoppers_lots.each do |hopper_lot|
      unless main_hoppers.has_key? hopper_lot.lot.ingredient_id
        main_hoppers[hopper_lot.lot.ingredient_id] = hopper_lot.hopper_id
      end
    end
    Hopper.update_all('main = true', :id => main_hoppers.values)
  end
end
