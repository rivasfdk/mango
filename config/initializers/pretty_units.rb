# Monkey patches RubyUnits::Unit.to_s to return "h:mm:ss" strings for seconds

require 'ruby-units'

module RubyUnitsExtensions
  def to_s(target_units=nil)
    if self.units == "s"
      to_hms(@scalar)
    elsif self.units == "degC"
      "#{@scalar} °C" 
    else
      return super(target_units)
    end
  end

  def to_hms(seconds)
    if seconds < 60
      Time.at(seconds).gmtime.strftime('%Ss')
    elsif seconds < 3600
      Time.at(seconds).gmtime.strftime('%Mm:%Ss')
    else
      Time.at(seconds).gmtime.strftime('%Hh%Mm:%Ss')
    end
  end	
end

RubyUnits::Unit.class_eval do
  prepend RubyUnitsExtensions
end
