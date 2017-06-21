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
set :environment, 'production'
set :job_template, "bash -l -i -c ':job'"
set :output, {:error => "/home/cron_error_log.log", :standard => "/home/cron_log.log"}

every :hour do
  rake "sync_db:local_to_remote"
end

# USAGE
# =====
# To write crontab:
# $  whenever --update-crontab
# To clear crontab:
# $ whenever -c
#
# For rake task sync_db:local_to_remote it is needed to set up SSH keys for password-less login, to do so run:
# $ ssh-keygen
# $ ssh-copy-id agromaticgroup@198.1.80.116