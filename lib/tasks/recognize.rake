require File.join(Rails.root, 'spec/support/sample_data') unless Rails.env.production?
require File.join(Rails.root, 'lib/ms_teams_tasks')
require File.join(Rails.root, 'infrastructure/cloud_deploy')

namespace :recognize do
  namespace :deploy do
    # Example invocation:
    # TASK_NAME=recognize-everest-task-deployments tag=qa COMMIT=8b0ec5b36330c3c393cd2684d7caa705bb94ad17 BUILD=24 AWS_DEFAULT_REGION=us-west-1 bundle exec rake recognize:deploy:register_task_definition
    desc 'Register task definition'
    task :register_task_definition do
      task_definition_family = ENV['TASK_NAME']
      tag, commit, build = ENV['tag'], ENV['COMMIT'], ENV['BUILD']
      image_tag = [tag, commit, build].join("_")
      CloudDeploy.register_task_definition(task_definition_family, image_tag)
    end
  end
  namespace :locales do
    desc 'Show missing locale keys for en locale'
    task :missing => :environment do
      prevent_production!
      puts `i18n-tasks missing --locales=en`
    end
  end

  desc "Drop; Create;"
  task :wipe => :environment do
    prevent_production!

    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
  end

  desc 'Drop; Create; AND migrate'
  task :reset => :wipe do
    prevent_production!

    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
  end

  desc 'Load a database backup and migrate, usage: recognize:load_db file=db/mydbbackup.sql'
  task :load_db => :wipe do
    prevent_production!

    f = ENV['file']
    raise "You must pass in a file with file='mysqldb.sql' parameter" if f.blank?

    c = ActiveRecord::Base.connection_config
    ustr = c[:username].blank? ? "" : "-u#{c[:username]}"
    pstr = c[:password].blank? ? "" : "-p#{c[:password]}"
    host = c[:host].blank? ? "" : "-h#{c[:host]}"
    if `which pv`.match(/not found/)
      puts "FYI: If you install 'pv' (pipeviewer) utility, you can get a progress indicator. "
      execstr = "mysql #{host} #{ustr} #{pstr} #{c[:database]} < #{f}"
      puts "running: #{execstr}"
      `#{execstr}`
    else
      execstr = "pv #{f} | mysql #{host} #{ustr} #{pstr} #{c[:database]}"
      puts "running: #{execstr}"
      `#{execstr}`
    end
    puts "Import complete. Now sanitizing and migrating"
    # Rake::Task['recognize:sanitize_db'].invoke
    Rake::Task['db:migrate'].invoke
  end

  desc 'Sanitize database'
  task :sanitize_db  => :environment do
    Rake::Task['recognize:sanitize_pii'].invoke
    Rake::Task['recognize:sanitize_saml'].invoke
    Rake::Task['recognize:sanitize_subscriptions'].invoke
    Rake::Task['recognize:sanitize_authentications'].invoke
    Rake::Task['recognize:sanitize_attachments'].invoke
    Rake::Task['recognize:sanitize_delayed_jobs'].invoke
  end

  desc 'Mask database'
  task :mask_db => :environment do
    # Fields for reference as of 2021-03-01
    # fields = {
    #   badges: [:name, :short_name, :long_name, :description, :anniversary_message, :long_description],
    #   comments: [:content],
    #   companies: [:name, :website, :domain, :slug, :kiosk_mode_key, :labels, :last_accounts_spreadsheet_import_file, :last_accounts_spreadsheet_import_problematic_records_file, :microsoft_team_id],
    #   company_customizations: [:email_header_logo, :certificate_background, :end_user_guide, :primary_header_logo, :secondary_header_logo],
    #   company_domains: [:domain],
    #   company_roles: [:name],
    #   company_settings: [:fb_workplace_community_id,:fb_workplace_token,:fb_workplace_post_to_group_id, :yammer_sync_groups, :microsoft_graph_sync_groups, :anniversary_recognition_custom_sender_name],
    #   completed_tasks: [:comment],
    #   contact_lists: [:contacts_raw],
    #   custom_field_mappings: [:key, :name, :provider_key, :mapped_to, :provider_type, :provider_attribute_key],
    #   fb_workplace_unclaimed_tokens: [:token],
    #   funds_account_manual_adjustments: [:comment],
    #   funds_txns: [:description],
    #   line_items: [:stripe_attributes],
    #   ms_teams_configs: [:settings],
    #   nomination_votes: [:message],
    #   point_activities: [:network],
    #   recognitions: [:message, :skills, :reason, :denial_message, :message_plain, :post_to_yammer_group_id],
    #   redemptions: [:response_message, :additional_instructions],
    #   rewards: [:description, :image, :additional_instructions],
    #   roles: [:name],
    #   subscriptions: [:email],
    #   tags: [:name],
    #   task_submission: [:description, :approval_comment],
    #   tasks: [:name],
    #   team: [:name, :network, :microsoft_graph_id],
    #   users: [:first_name, :last_name, :email, :crypted_password, :slug, :job_title, :current_login_ip, :last_login_ip, :contacts_raw, :yammer_id, :phone, :microsoft_graph_id, :unique_key, :outlook_identity_token, :display_name, :fb_workplace_id, :user_principal_name,]
    # }
    puts "1. Clearing out User#unique_key to avoid conflicts"
    User.with_deleted.update_all(unique_key: nil)
    Company.with_deleted.update_all(has_theme: false, parent_company_id: nil)

    puts "2. Clearing out orphaned records"
    bad_company_ids = [217, 9657]
    Team.with_deleted.where(company_id: bad_company_ids).map(&:really_destroy!)

    puts "3. Running full mask rake task"
    Rake::Task['db:mask'].invoke

    puts "4. Updating PointActivies...this may take a few minutes..."
    PointActivity.joins(:company).update_all("point_activities.network = companies.domain")
  end

  desc 'Backup mysql db'
  task :backup_db => :environment do
    filename = "recognize_#{Rails.env.to_s.downcase}_#{Time.now.strftime("%Y%m%d%H%I%S")}.sql.gz"
    filepath = "tmp/#{filename}"

    c = ActiveRecord::Base.connection_config
    ustr = c[:username].blank? ? "" : "-u#{c[:username]}"
    pstr = c[:password].blank? ? "" : "-p#{c[:password]}"
    host = c[:host].blank? ? "" : "-h#{c[:host]}"
    execstr = "mysqldump --default-character-set=utf8mb4 #{host} #{ustr} #{pstr} #{c[:database]} | gzip --best > #{filepath}"
    `#{execstr}`
    puts filepath
  end

  desc 'Upload a backup file to s3'
  task :upload_backup, :file, :needs do |t, args|
    raise "This task must be run in production environment to connect with AWS" unless Rails.env.production?
    raise "You must specify a path to a file to upload with: file=<pathtofile>" unless ENV['file'].present? or args[:file].present?

    f  = ENV['file'] || args[:file]
    b = BackupAttachment.new(file: File.open(f))
    b.save!
  end

  desc 'Make a backup of mysql db and upload it to s3'
  task :backup_and_upload => :environment do
    backupfile = capture_stdout {Rake::Task['recognize:backup_db'].invoke}
    Rake::Task['recognize:upload_backup'].invoke(backupfile.strip)
  end

  desc 'Sanitize attachments, the referenced files themselves arent brought over, so kill the records'
  task :sanitize_attachments => :environment do
    prevent_production!

    ActiveRecord::Base.connection.execute("truncate attachments") rescue nil

  end

  desc 'Sanitize the email addresses for a particular database by adding a new tld'
  task :sanitize_pii => :environment do
    prevent_production!

    ActiveRecord::Base.connection.execute("update users set email=concat(email, '.not.real.tld') where email NOT LIKE '%recognizeapp.com' AND email NOT LIKE '%planet.io'")
    ActiveRecord::Base.connection.execute("update users set unique_key=concat(unique_key, '.not.real.tld') where unique_key NOT LIKE '%recognizeapp.com' AND email NOT LIKE '%planet.io'")
    ActiveRecord::Base.connection.execute("update companies set domain=concat(domain, '.not.real.tld') where domain NOT LIKE '%recognizeapp.com' AND domain NOT LIKE '%planet.io' AND domain <> 'users'")
    ActiveRecord::Base.connection.execute("update company_domains set domain=concat(domain, '.not.real.tld') where domain NOT LIKE '%recognizeapp.com' AND domain NOT LIKE '%planet.io' AND domain <> 'users'")
    ActiveRecord::Base.connection.execute("update users set network=concat(network, '.not.real.tld') where network NOT LIKE '%recognizeapp.com' AND network NOT LIKE '%planet.io' AND network <> 'users'")    rescue nil
    ActiveRecord::Base.connection.execute("update teams set network=concat(network, '.not.real.tld') where network NOT LIKE '%recognizeapp.com' AND network NOT LIKE '%planet.io' AND network <> 'users'")    rescue nil
    ActiveRecord::Base.connection.execute("update recognition_recipients set recipient_network=concat(recipient_network, '.not.real.tld') where recipient_network NOT LIKE '%recognizeapp.com' AND recipient_network NOT LIKE '%planet.io' AND recipient_network <> 'users'")    rescue nil
    ActiveRecord::Base.connection.execute("update support_emails set email=concat(email, '.not.real.tld') where email NOT LIKE '%recognizeapp.com' AND email NOT LIKE '%planet.io'")
    ActiveRecord::Base.connection.execute("update users set phone='' where email NOT LIKE '%recognizeapp.com' AND email NOT LIKE '%planet.io'")
    ActiveRecord::Base.connection.execute("truncate table sessions")
  end


  desc 'Sanitize saml configurations'
  task :sanitize_saml => :environment do
    prevent_production!

    ActiveRecord::Base.connection.execute("truncate saml_configurations") rescue nil
    Rake::Task['recognize:load_recognize_saml'].invoke
  end

  desc 'Load  recognize saml configuration'
  task :load_recognize_saml => :environment do
    prevent_production!

    path = File.join(Rails.root, "config/recognize_saml.yml")
    if !File.file?(path)
      puts "No local configuration found at config/recognize_saml.yml, skipping loading local saml config..."
    else
      yaml = YAML.load_file(path)
      yaml = yaml[ENV['SITE'] || Rails.env]
      recognize = Company.find(1)
      config = recognize.saml_configuration || recognize.build_saml_configuration
      config.is_enabled = true
      config.entity_id = yaml["entity_id"]
      config.sso_target_url = yaml["sso_url"]
      config.certificate = yaml["certificate"]
      config.save!
    end
  end

  desc 'Sanitize subscription data because it may point to a different Stripe endpoint(live vs test)'
  task :sanitize_subscriptions => :environment do
    prevent_production!

    ActiveRecord::Base.connection.execute("truncate subscriptions") rescue nil
  end

  task :sanitize_authentications => :environment do
    prevent_production!

    user_ids = User.where.not(network: "recognizeapp.com").where.not(network: "planet.io").pluck(:id)
    Authentication.where(user_id: user_ids).delete_all
  end

  task :sanitize_delayed_jobs => :environment do
    prevent_production!

    Delayed::Job.delete_all
  end

  desc "Initialize Recognize. To be run from fresh install."
  task :init => :environment do
    prevent_production!
    ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = "1"

    Rake::Task['tmp:clear'].invoke
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    # Rake::Task['db:migrate'].invoke

    load "#{Rails.root.to_s}/db/schema.rb" # dont load schema b/c there is some issue with mysql index lengths when done this way
    Rails.application.load_seed

  end

  desc "Resets all roles assignments"
  task :reset_roles => :environment do
    prevent_production!

    UserRole.delete_all
  end

  desc "Deletes all the badges and initializes with a new set"
  task :initialize_badges => :environment do
    prevent_production!

    ActiveRecord::Base.connection.execute("TRUNCATE badges")
    Badge.reset_column_information
    Badge::SET.each{|b| FactoryBot.create("#{b}_badge") }
  end

  desc 'Generate a sample company with users, recognitions and approvals'
  task :generate_sample_company => :environment do
    prevent_production!

    domain = ENV['domain']
    num_users = ENV['num_users'] || 9423
    num_recognitions = ENV['num_recognitions'] || 21

    if domain.blank?
      puts "Please specify a domain with the command 'rake recognize:generate_sample_company domain=yourdomain.com"

    else

      if Company.find_by_domain(domain).present?
        puts "sorry that domain already exists, try a different one or run 'rake recognize:init' to start fresh"
      else
        puts "generating #{domain} with #{num_users} users and #{num_recognitions} recognitions"
        sample_data = SampleData::Generator.new(domain, num_users.to_i, num_recognitions.to_i)
        sample_data.generate!
      end

    end
  end

  desc 'add images to the initech data set'
  task :add_images_to_initech => :environment do
    prevent_production!

    data = [[8, "rlivingston@initech.com", "http://ia.media-imdb.com/images/M/MV5BMTg2NjY4MjcwN15BMl5BanBnXkFtZTcwMjM4MzI0Mg@@._V1._SY314_CR138,0,214,314_.jpg"],
    [9, "jenn.anistown@initech.com", "http://ia.media-imdb.com/images/M/MV5BNjk1MjIxNjUxNF5BMl5BanBnXkFtZTcwODk2NzM4Mg@@._V1._SY314_CR2,0,214,314_.jpg"],
    [10, "david.herman@initech.com", "http://ia.media-imdb.com/images/M/MV5BMTQ0NDQ2ODY5OV5BMl5BanBnXkFtZTYwMTQxOTgy._V1._SY314_CR8,0,214,314_.jpg"],
    [11, "ajay.naidu@initech.com", "http://ia.media-imdb.com/images/M/MV5BMTY5NjU0NTU5OV5BMl5BanBnXkFtZTYwMTU4MzA2._V1._SY314_CR4,0,214,314_.jpg"],
    [12, "diedrich.bader@initech.com", "http://ia.media-imdb.com/images/M/MV5BMTkzMTkyNzYyOV5BMl5BanBnXkFtZTYwNTMyNDE0._V1._SY314_CR7,0,214,314_.jpg"],
    [13, "alexandra.wentworth@initech.com", "http://ia.media-imdb.com/images/M/MV5BMTgzMzU1MzI5N15BMl5BanBnXkFtZTcwMzE2Mzc1MQ@@._V1._SY314_CR10,0,214,314_.jpg"],
    [14, "kinna.mcinroe@initech.com", "http://ia.media-imdb.com/images/M/MV5BMjE4Nzg3NzUzMV5BMl5BanBnXkFtZTcwMDY1MzI3NA@@._V1._SX214_CR0,0,214,314_.jpg"],
    [15, "greg.pitts@initech.com", "http://ia.media-imdb.com/images/M/MV5BMTg3NDU1NDY0Ml5BMl5BanBnXkFtZTcwNzA3NjgyNA@@._V1._SY314_CR18,0,214,314_.jpg"],
    [16, "peter.gibbons@initech.com",  "http://ia.media-imdb.com/images/M/MV5BMTg2NjY4MjcwN15BMl5BanBnXkFtZTcwMjM4MzI0Mg@@._V1._SY314_CR138,0,214,314_.jpg"],
    [17, "samir.nagheenanajar@initech.com", "http://ia.media-imdb.com/images/M/MV5BMTM5NjQ2OTIwMV5BMl5BanBnXkFtZTcwMjcxOTYyMQ@@._V1._SY314_CR5,0,214,314_.jpg"],
    [18, "bill.lumbergh@initech.com", "http://ia.media-imdb.com/images/M/MV5BMTQwODU5MTU3OF5BMl5BanBnXkFtZTcwMzk2NzMzMw@@._V1._SY314_CR9,0,214,314_.jpg"],
    [19, "milton.waddams@initech.com", "http://ia.media-imdb.com/images/M/MV5BMTg1MDc4MjExNF5BMl5BanBnXkFtZTcwMzQ4OTY0Mw@@._V1._SX214_CR0,0,214,314_.jpg"]]

    data.each{|u|
      user = User.find_by_email(u[1])
      user.avatar.remote_file_url = u[2]
      user.avatar.save!
    }

    #hack delete ron livingston for sxsw
    User.find_by_email("rlivingston@initech.com").destroy
  end

  desc 'Prep initech sample database'
  task :prep_initech => :environment do
    prevent_production!
    SampleData::File.generate!("db/sample_recognition_data.csv", "db/initech_users.csv", network: 'initech.com')
  end
  desc 'Prep theoffice sample database'
  task :prep_theoffice => :environment do
    prevent_production!
    SampleData::File.generate!("db/sample_recognition_data.csv", "db/theoffice_users.csv", network: 'dundermifflin.com')
  end

  desc 'Prep Planet sample database'
  task :prep_planet => :environment do
    prevent_production!
    SampleData::File.generate!("db/sample_recognition_data.csv", "db/planet_users.csv", network: 'planet.io')
  end

  desc 'Generate daily sample data for planet and recognize'
  task :generate_daily_sample_data => :environment do
    prevent_production_server!
    SampleData::File.generate!('db/sample_recognition_data.csv', 'db/planet_users.csv', network: 'planet.io') rescue nil
    SampleData::File.generate!('db/sample_recognition_data.csv', 'db/initech_users.csv', network: 'planet.io') rescue nil
    SampleData::File.generate!('db/sample_recognition_data.csv', 'db/planet_users.csv', network: 'recognizeapp.com') rescue nil
    SampleData::File.generate!('db/sample_recognition_data.csv', 'db/initech_users.csv', network: 'recognizeapp.com') rescue nil
  end

  desc 'Get users emails as a line delimited file'
  task :user_list => :environment do
    filename = ENV['filename']
    puts filename
    if filename.blank?
      puts "Usage: rake recognize:user_list filename=<yourfilename>"
      exit
    end
    list = User.marketable_users.collect{|s| s.email}.join("\n")
    File.open(filename, 'w'){|f| f.write(list)}
  end

  desc "Export a company's accounts page"
  task :export_users => :environment do
    domain = ENV['domain']

    puts "Exporting users for #{domain}"
    if domain.blank?
      puts "Usage: rake recognize:export_users domain=<domain>"
      exit
    end

    c = Company.where(domain: domain).first
    CSV.open("#{domain}-users.csv", "wb") do |csv|
      csv << ["Email", "First name", "Last name", "Manager Name", "Manager email", "Teams", "Roles", "Status", "Created at"]
      c.users.each do |u|
        data = []
        data << u.email
        data << u.first_name
        data << u.last_name
        data << (u.manager.present? ? "#{u.manager.full_name}" : nil)
        data << (u.manager.present? ? "#{u.manager.email}" : nil)
        data << u.teams.map(&:name).join(", ")
        data << (u.roles.map{|r| r.long_name.humanize} + u.company_roles.map(&:name)).join(", ")
        data << u.status
        data << u.created_at
        csv << data
      end
    end

  end

  desc 'Sync users as groups in Mailchimp'
  task :mailchimp => :environment do
    category_name = Time.now.to_formatted_s(:db).gsub(" ", '-').gsub(":","-")
    batches = {}

    puts "Setting up Mailchimp groups..."
    api_key = Recognize::Application.config.rCreds['mailchimp']['api_key']
    gibbon = Gibbon::Request.new(api_key: api_key, debug: false)
    master_list_id = Recognize::Application.config.rCreds['mailchimp']['master_list_id']
    category = gibbon.lists(master_list_id).interest_categories.create(body: {title: category_name, type: "hidden"})
    group = gibbon.lists(master_list_id).interest_categories(category.body["id"]).interests.create(body: {name: category_name})

    puts "Gathering users, please wait..."
    users = User.all_marketable_users
    total = users.length

    puts "Assembling bulk request to Mailchimp..."
    operations = []
    users.each_with_index do |u, i|
      print "#{i}/#{total}\r" if (i % 100 == 0)
      # gibbon.lists(master_list_id).members(Digest::MD5.hexdigest("peter@recognizeapp.com")).upsert(body: {email_address: "peter@recognizeapp.com", merge_fields: {ROLES: "company_admin,employee"}})
      # csv << [u.email, u.roles.map(&:name).join(","), u.company.allow_admin_dashboard, u.subscription.try(:status)]
      operations << {
        method: "PUT",
        path: "lists/#{master_list_id}/members/#{Digest::MD5.hexdigest(u.email.downcase)}",
        body: {
          email_address: u.email,
          interests: {group.body["id"] => true},
          status_if_new: "subscribed",
          merge_fields: {
            FNAME: u.first_name.to_s,
            LNAME: u.last_name.to_s,
            ROLES: u.roles.map(&:name).join(",").to_s,
            ADMIN_DASH: u.company.allow_admin_dashboard? ? "true" : "false",
            SUB_STATUS: u.company.subscription.try(:status_label).to_s,
            NETWORK: u.network.to_s
          }
        }.to_json
      }
    end

    puts "Sending batch operation...(this may take a little while)..."
    batch = gibbon.batches.create(body: {operations: operations})
    batches[:marketable_users] = batch

    puts "Batch created: #{batch.body["id"]}"
    while(batch.body["completed_at"].blank?) do
      body = batch.body
      print "#{body["status"]}: #{body["finished_operations"]}/#{body["total_operations"]}                  \r" #make sure to clear far to the right
      batch = gibbon.batches(body["id"]).retrieve
      sleep 1
    end
    puts "Finished: #{batch.body["finished_operations"]} finished /#{batch.body["total_operations"]} total | #{batch.body["errored_operations"]} errored"

    puts "Now syncing unsubscribes..."
    unsubscribes = User.all_unsubscribes
    total = unsubscribes.length
    unsubscribe_group = gibbon.lists(master_list_id).interest_categories(category.body["id"]).interests.create(body: {name: category_name+"-unsubscribes"})
    operations = []
    unsubscribes.each_with_index do |u, i|
      print "#{i}/#{total}\r" if (i % 100 == 0)
      # gibbon.lists(master_list_id).members(Digest::MD5.hexdigest("peter@recognizeapp.com")).upsert(body: {email_address: "peter@recognizeapp.com", merge_fields: {ROLES: "company_admin,employee"}})
      # csv << [u.email, u.roles.map(&:name).join(","), u.company.allow_admin_dashboard, u.subscription.try(:status)]
      operations << {
        method: "PUT",
        path: "lists/#{master_list_id}/members/#{Digest::MD5.hexdigest(u.email.downcase)}",
        body: {
          email_address: u.email,
          interests: {unsubscribe_group.body["id"] => true},
          status: "unsubscribed"
        }.to_json
      }
    end

    puts "Sending batch unsubscribe operation...(this may take a little while)..."
    batch = gibbon.batches.create(body: {operations: operations})
    batches[:unsubscribes] = batch

    puts "Batch created: #{batch.body["id"]}"
    while(batch.body["completed_at"].blank?) do
      body = batch.body
      print "#{body["status"]}: #{body["finished_operations"]}/#{body["total_operations"]}                  \r" #make sure to clear far to the right
      batch = gibbon.batches(body["id"]).retrieve
      sleep 1
    end
    puts "Finished: #{batch.body["finished_operations"]} finished /#{batch.body["total_operations"]} total | #{batch.body["errored_operations"]} errored"

    # Get and display batch errors
    batches.each do |batch_name, batch|
      batch_id = batch.body["id"]
      batch_data = gibbon.batches(batch_id).retrieve
      response_url = batch_data.body["response_body_url"]
      filename = URI.parse(response_url).path.gsub(/^\//,'')
      dirname = File.basename(filename, '.tar.gz')
      FileUtils::mkdir_p "tmp/#{dirname}"
      raw_file = RestClient.get(response_url)
      File.open("tmp/#{dirname}/#{filename}", 'wb') {|f| f.write(raw_file)}
      `tar -xvzf tmp/#{dirname}/#{filename} --directory tmp/#{dirname}/`
      files = Dir["tmp/#{dirname}/*.json"]
      errors = files.inject([]) do |set, filename|
        raw_json = File.read(filename)
        json = JSON.parse(raw_json)
        set += json.select{|d| d["status_code"] != 200}
        set
      end

      File.open("tmp/#{dirname}/#{batch_name}-errors.log", 'wb') do |f|
        errors.each do |error|
          f.write(error.to_s+"\n")
        end
      end

      File.open("tmp/#{dirname}/#{batch_name}-errors.json", 'wb') do |f|
        f.write(errors.to_json)
      end

    end

  end

  desc 'Get Yammer users emails as a line delimited file'
  task :yammer_user_list => :environment do
    filename = ENV['filename']
    puts "Writing #{filename}"
    if filename.blank?
      puts "Usage: rake recognize:user_list filename=<yourfilename>"
      exit
    end

    list = User
      .marketable_yammer_users
      .map{|u| [unsanitize(u.email), u.first_name, u.last_name, unsanitize(u.company.domain)].join(",")}
      .join("\n")

    File.open(filename, 'w'){|f| f.write(list)}
  end

  desc 'Get users for newsletter'
  task :newsletter_user_list => :environment do
    filename = ENV['filename']
    puts filename
    if filename.blank?
      puts "Usage: rake recognize:newsletter_user_list filename=<yourfilename>"
      exit
    end
    list = User.newsletter_users.collect{|s| s.email}.join("\n")
    File.open(filename, 'w'){|f| f.write(list)}
  end

  desc 'prime all the caches, also wipes out all tmp'
  task :prime_caches => :environment do
    Company.prime_caches!
  end

  desc 'run tests'
  task :test  do
    result = system("bundle exec rspec spec")
    if !result
      puts "Hmm...looks like we had a catastrophic failure.  Fear not, lets re-initialize your test db and see what happens"
      result = system("bundle exec rake recognize:init RAILS_ENV=test; bundle exec rspec spec")
    end
    puts "The output of test completed with status: #{result.inspect}"
  end

  desc 'Sync coupons with Stripe'
  task :sync_coupons  => :environment do
    Coupon.sync_with_stripe!
  end

  desc 'Unsubscribe a list of emails'
  task :unsubscribe => :environment do
    filename = ENV['filename']
    puts filename
    if filename.blank?
      puts "Usage: rake recognize:unsubscribe filename=<yourfilename>"
      exit
    end
    f = File.open(filename)

    emails = f.readlines.map { |email|  email.chomp}
    users = User.includes(:email_setting).where(email: emails)
    EmailSetting.where(user_id: users.map(&:id)).update_all(["email_settings.global_unsubscribe = ?", true])
  end

  desc 'Ensure badges'
  task :ensure_badges => :environment do
    prevent_production!

    domains = ["recognizeapp.com", "planet.io"]
    badges_images = Dir["./app/assets/images/badges/200/*"]
    # companies = Company.all
    companies = Company.where(domain: domains)
    companies.each do |c|
      Badge.where(company_id: c.id).each do |badge|
        next if badge.image.present?
        badge.remove_image!
        badge.save!(validate: false)
        badge_image = badges_images.detect{|i| i.match(/#{badge.short_name}/i)} || badges_images[rand(badges_images.length)]
        puts "Adding badge to #{c.domain} - #{badge.short_name} - #{badge_image}"
        badge.image = File.open(badge_image)
        badge.save!(validate: false)
      end
    end
    Badge.where(company_id: nil).each do |badge|
      next if badge.image.present?
      badge.remove_image!
      badge.save!(validate: false)
      badge_image = badges_images.detect{|i| i.match(/#{badge.short_name}/i)} || badges_images[rand(badges_images.length)]
      puts "Adding badge to default set - #{badge.short_name} - #{badge_image}"
      badge.image = File.open(badge_image)
      badge.save!(validate: false)
    end
  end

  desc 'Ensure avatars'
  task :ensure_avatars => :environment do
    prevent_production!

    domains = ["recognizeapp.com", "planet.io"]
    avatar_images = CSV.readlines("db/planet_users.csv").map{|u| u[1]}
    # companies = Company.all
    companies = Company.where(domain: domains)
    companies.each do |c|
      c.users.each do |user|
        next if user.avatar.file.present?
        avatar_image = avatar_images[rand(avatar_images.length)]
        puts "Adding avatar to #{c.domain} - #{user.email} - #{avatar_image}"
        user.avatar.remote_file_url = avatar_image
        user.avatar.save!(validate: false)
      end
    end
  end

  desc 'Ensure badges and avatars'
  task :ensure_badges_and_avatars => [:ensure_badges, :ensure_avatars] do
    # prevent_production!
    # Rake::Task['recognize:ensure_badges'].invoke
    # Rake::Task['recognize:ensure_avatars'].invoke
  end

  desc 'Ensure rewards images'
  task :ensure_rewards_images => [:environment] do
    c = Company.find(1)
    c.rewards.each do |r|
      next unless r.image_url.present?
      puts "Grabbing reward image: #{r.image_url}"
      `mkdir -p #{File.dirname(r.image_url).gsub('/l.recognizeapp.com:50000',Rails.root.to_s)}`
      url = r.image_url.gsub('//l.recognizeapp.com:50000/uploads/development', 'https://recognize-assets.s3.amazonaws.com/uploads/production')
      destination_path = File.dirname(Rails.root.to_s+"/public/"+r.image_url.gsub('//l.recognizeapp.com:50000/',''))
      `wget #{url} -P #{destination_path}`
    end
  end

  desc 'Compile themes for companies with custom styles'
  task :compile_themes => :environment do
    CustomTheme.compile_all_company_themes!
  end

  desc 'Bootstrap rewards for development'
  task :bootstrap_rewards => :environment do
    prevent_production!

    tango = Rewards::RewardService.create_reward_provider('tango_card')
    tango.activate!

    begin
      Rewards::RewardService.sync_provider_rewards
    rescue SocketError
      puts "Could not sync rewards. Perhaps you don't have intarwebs? When you have network, run: \n\n\tRewards::RewardService.sync_provider_rewards\n\n"
    end

    company = Company.find(1)
    puts "Bootstrapping rewards budget for #{company.domain}"
    company.primary_funding_account.save
    company.funds_accounts.create!(recognize_admin: true, currency_code: company.currency) unless Rewards::FundsAccount.recognize_admin_accts.first.present?
    Rewards::FundsAccountService.manual_credit(company.primary_funding_account, 1000, 'Deposit from bootstrap command')
  end

  namespace :db do
    # clear db faster without dropping & re-creating tables (unlike db:reset)
    # useful for removing duplicate/leftover data in test env
    desc "Truncate all tables"
    task truncate: :environment do
      prevent_production!
      conn = ActiveRecord::Base.connection
      tables = conn.execute("show tables").map { |r| r[0] }
      tables.delete "schema_migrations"
      tables.each { |t| conn.execute("TRUNCATE #{t}") }
    end
  end


  desc "API Routes"
  task :api_routes => :environment do
    Api::V2::Base.routes.each do |api|
      method = api.request_method.ljust(10)
      path = api.path
      puts "     #{method} #{path}"
    end
  end

  desc 'MsTeams Generate Manifest'
  task :generate_ms_teams_manifest => :environment do
    MsTeamsTasks.generate_manifest_zip
  end
end

require "stringio"

def capture_stderr
  previous, $stderr = $stderr, StringIO.new
  yield
  $stderr.string
ensure
  $stderr = previous
end

def capture_stdout
  previous, $stdout = $stdout, StringIO.new
  yield
  $stdout.string
ensure
  $stdout = previous
end

def prevent_production!
  prevent_production_env!
  prevent_production_server!
end

def prevent_production_env!
  raise "You may not run this in production environment!".red if Rails.env.production?
end

def prevent_production_server!
  raise "You may not run this against recognizeapp.com".red if Recognize::Application.config.host == "recognizeapp.com"
end

def unsanitize(str)
  str.gsub(".not.real.tld", "")
end
