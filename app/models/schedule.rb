class Schedule < ActiveRecord::Base
  has_many :batch

  validates_uniqueness_of :name
  validates_presence_of :start_hour, :end_hour

  def self.get_current_schedule(time)
    # Replace this with magic shit
    Schedule.first
  end
end
