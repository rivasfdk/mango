class Carrier < ActiveRecord::Base
  has_many :trucks
  accepts_nested_attributes_for :trucks

  validates_presence_of :name
  validates_length_of :name, :within => 3..40
  before_save :create_code
  
  def create_code
    unless self.id
      last = Carrier.last
      if last.nil?
        self.code = '001'
      else
        self.code = last.code.succ
      end
    end
  end
end
