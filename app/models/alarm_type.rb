class AlarmType < ActiveRecord::Base
  has_many :alarms
  validates_presence_of :description
end
