class Carrier < ActiveRecord::Base
  attr_protected :id

  has_many :trucks
  accepts_nested_attributes_for :trucks

  validates_presence_of :name
  validates_length_of :name, :within => 3..40
  validates :name, uniqueness: { case_sensitive: false }
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
