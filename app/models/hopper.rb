class Hopper < ActiveRecord::Base
  belongs_to :scale
  has_many :hopper_lot

  validates_uniqueness_of :number, :scope => :scale_id
  validates_presence_of :number, :scale
  validates_numericality_of :number, :only_integer => true, :greater_than_or_equal_to => 0

  def self.find_actives(scale_id)
    actives = []
    hoppers = Hopper.find :all, :conditions => ['scale_id = ?', scale_id], :order => 'number ASC'
    hoppers.each do |hop|
      lots = HopperLot.find :first, :conditions => ['hopper_id = ? and active = ?', hop.id, true], :include => {:lot=>:ingredient}
      actives << {
        :lot => lots,
        :hopper_id => hop.id,
        :number => hop.number,
        :name => hop.name,
      }
    end
    #actives.sort_by {|hop| hop[:number]}
    return actives
  end

  def self.actives_to_select
    actives = []

    hoppers = Hopper.find :all, :include => :scale, :order => 'number ASC'
    hoppers.each do |hop|
      lots = HopperLot.find :first, :conditions => ['hopper_id = ? and active = ?', hop.id, true]
      next if lots.nil?
      name = hop.name == " " ? hop.number : hop.name
      actives << ["Tolva #{hop.name} - #{lots.lot.ingredient.name} (L: #{lots.lot.code})", lots.id]
    end
    return actives
  end
  
  def find_active
    lot = HopperLot.find :first, :conditions => ['hopper_id = ? and active = ?', self.id, true]
  end

  def deactivate_all_lots
    self.hopper_lot.each do |i|
      i.active = false
      i.save
    end
  end

  def update_lot(id)
    deactivate_all_lots
    return true if id.blank?
    h = HopperLot.new(:lot_id => id)
    h.hopper_id = self.id
    return h.save
  end

  def update_name(name)
    self.name = name
    self.save
  end

  def update_scale(scale_id)
    self.scale_id = scale_id
    self.save
  end

  def eliminate
    begin
      b = BatchHopperLot.find :all, :include => [:hopper_lot], :conditions => {:hoppers_lots=>{:hopper_id => self.id}}
      if b.length > 0
        errors.add(:foreign_key, 'no se puede eliminar porque tiene registros asociados')
        return
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
end
