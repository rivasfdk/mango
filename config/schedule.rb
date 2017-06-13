# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end
#
# Learn more: http://github.com/javan/whenever
#
set :environment, 'development'
set :job_template, "bash -l -i -c ':job'"
#set :output, {:error => "/home/gaby/mango-v2/cron_error_log.log", :standard => "/home/gaby/mango-v2/cron_log.log"}

every :hour do
  rake "db:sync_remote_db"
end

# USAGE
# =====
# To write crontab:
# $ whenever --update-crontab
# To clear crontab:
# $ whenever -c