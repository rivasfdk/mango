namespace :sync_db do
  desc 'Sync local and remote databases! Backup local database, transfer to remote server on cPanel and import it'
  task local_to_remote: :environment do
    # config
    datestamp = Time.now.strftime("%Y%m%d%H%M")
    max_backups = 2
    local_backup_folder = "../tmp_backup/"
    remote_backup_folder = "public_html/liderpollo/tmp_backup/"
    remote_app_folder = "public_html/liderpollo/mango"
    remote_db_user = "agromati_lider"
    remote_db = "agromati_liderpollo"
    
    # backup database
    FileUtils.mkdir_p(local_backup_folder) unless File.exist?(local_backup_folder)
    db_config   = ActiveRecord::Base.configurations[ENV['RAILS_ENV']]
    backup_file = File.join(local_backup_folder, "#{db_config['database']}_#{datestamp}.sql")
    `test -f #{backup_file}* && rm #{backup_file}*`
    `mysqldump -u #{db_config['username']} -p#{db_config['password']} #{db_config['database']} > #{backup_file}`
    raise "Unable to make DB backup!" if ( $?.to_i > 0 )

    # delete unwanted backups
    all_backups = Dir.new(local_backup_folder).entries.sort[2..-1].reverse
    puts "Created backup: #{backup_file} successfully!"
    unwanted_backups = all_backups[max_backups..-1] || []
    for unwanted_backup in unwanted_backups
    FileUtils.rm_rf(File.join(local_backup_folder, unwanted_backup))
    end
    puts "Deleted #{unwanted_backups.length} backups, #{all_backups.length - unwanted_backups.length} backups available"

    # Sync local with remote backup folder   
    system("rsync --remove-source-files -avze ssh --delete #{local_backup_folder} #{server_user_and_host}:#{remote_backup_folder}")
    
    if File.exist?(backup_file)
      sleep 1
    end
    
    # Import local backup to remote mysql database
    execute_on_server %(
        cd #{remote_app_folder} && bundle exec rake db:drop db:create RAILS_ENV=production \
        && mysql -u #{remote_db_user} -p"`cat config/database.yml | grep password | awk '{ print $2 }'`" #{remote_db} < #{backup_file} \
        && bundle exec rake db:migrate RAILS_ENV=production
    )

  end

  def execute_on_server(commands)
    system %(ssh -T #{server_user_and_host} << 'SSH'
      #{commands}
    SSH).split("\n").map(&:strip).join("\n")
  end

  def server_user_and_host
    'agromaticgroup@198.1.80.116'
  end

end