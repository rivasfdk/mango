class AlarmType < ActiveRecord::Base
  attr_protected :id

  has_many :alarms
  validates_presence_of :description
end
