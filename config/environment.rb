# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Mango::Application.initialize!

require 'pdf/easy_report'

CalendarDateSelect.format = :iso_date
CalendarDateSelect.default_options.update(:locale => 'es')
CalendarDateSelect.default_options.update(:popup => 'force')
