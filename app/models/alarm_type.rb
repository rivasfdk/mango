class AlarmType < ActiveRecord::Base
  has_many :alarms
  validates_presence_of :code, :description
  
  def to_collection_select
    return "#{self.code} - #{self.description}"
  end
end
