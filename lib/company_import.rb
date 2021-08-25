# encoding: UTF-8
# export spreadsheet to csv into ~/Downloads
# scp ~/Downloads/goodway.csv web@54.244.90.62:./sites/recognizeapp.com/current/tmp/
# Run this with: [RAILS_ENV=production] bin/rails r lib/company_import.rb

# bin/rails r lib/company_import.rb --file=tmp/sonaemc.csv --schema=1 --domain=sonaemc.com --sender-email=PGTORRES@sonaemc.com --invite=true
# bin/rails r lib/company_import.rb --file=tmp/investorsgroup-hr.csv --schema=4 --domain=investorsgroup.com-Human-Resources --sender-email=trevor.hubert@investorsgroup.com --invite=false
# bin/rails r lib/company_import.rb --file=tmp/investorsgroup-marketing.csv --schema=5 --domain=investorsgroup.com-marketing --sender-email=trevor.hubert@investorsgroup.com --invite=false --date-format=%m/%d/%Y
# bin/rails r lib/company_import.rb --file=tmp/amtwoundcare.csv --schema=6 --domain=amtwoundcare.com --sender-email=tessa.hammond@amtwoundcare.com --date-format=%m/%d/%Y
# bin/rails r lib/company_import.rb --file=tmp/premiers.csv --schema=7 --domain=premiers.qld.gov.au --sender-email=renee.shea@premiers.qld.gov.au
# bin/rails r lib/company_import.rb --file=tmp/oqpc.csv --schema=8 --domain=premiers.qld.gov.au --sender-email=renee.shea@premiers.qld.gov.au
# bin/rails r lib/company_import.rb --file=tmp/igt-pilot.csv --schema=3 --domain=igt.com --sender-email=tonia.fulton@igt.com --invite=false
# bin/rails r lib/company_import.rb --file=tmp/brandtone.csv --schema=1 --domain=brandtone.com --sender-email=jay.ross@brandtone.com
# bin/rails r lib/company_import.rb --file=tmp/swdeligroup.csv --schema=9 --domain=swdeligroup.com --sender-email=kgrozdanich@swdeligroup.com
# bin/rails r lib/company_import.rb --file=tmp/shiningstartherapy.csv --schema=10 --domain=shiningstartherapy.com --sender-email=babraggs@shiningstartherapy.com --date-format=%m/%d/%Y --invite=false --extra-data=tmp/data.yml
# bin/rails r lib/company_import.rb --file=tmp/jetprivilege.csv --schema=10 --domain=jetprivilege.com --sender-email=manish.dureja@jetprivilege.com --date-format=%m/%d/%Y --invite=false

# bin/rails r lib/company_import.rb --file=tmp/patriot.csv --schema=11 --domain=patriotenergygroup.com --sender-email=jbourgeois@patriotenergygroup.com --date-format=%m/%d/%Y --invite=false
# bin/rails r lib/company_import.rb --file=tmp/mintenergy.csv --schema=11 --domain=mintenergy.net --sender-email=jbourgeois@patriotenergygroup.com --date-format=%m/%d/%Y --invite=false
# bin/rails r lib/company_import.rb --file=tmp/pgn.csv --schema=1 --domain=pgnsa.com.br --sender-email=pedro.pecanha@pgnsa.com.br --date-format=%m/%d/%Y
# bin/rails r lib/company_import.rb --file=tmp/dealogic.csv --schema=4 --domain=dealogic.com --sender-email=xxx --date-format=%d/%m/%Y --invite=false --update-only=true
# bin/rails r lib/company_import.rb --file=tmp/mint.csv --schema=11 --domain=mintenergy.net --sender-email=jbourgeois@patriotenergygroup.com --date-format=%m/%d/%Y --invite=false --remove-users=true
# bin/rails r lib/company_import.rb --file=tmp/patriot.csv --schema=11 --domain=patriotenergygroup.com --sender-email=jbourgeois@patriotenergygroup.com --date-format=%m/%d/%Y --invite=false --remove-users=true
# bin/rails r lib/company_import.rb --file=tmp/mercom.csv --schema=11 --domain=mercomcorp.com --sender-email=courtney.newman@mercomcorp.com --date-format=%m/%d/%y --invite=false --birthday-format="%m/%d/%y"
# bin/rails r lib/company_import.rb --file=tmp/parker.csv --schema=11 --domain=parkeronline.org --sender-email=cvanderpool@parkeronline.org --date-format=%m/%d/%y --invite=false --birthday-format="%m/%d"
# bin/rails r lib/company_import.rb --file=tmp/sydney.csv --schema=12 --domain=sydney.edu.au-Finance --sender-email=marc.haynes@sydney.edu.au --date-format=%m/%d/%Y --invite=false 
# bin/rails r lib/company_import.rb --file=tmp/campbell2.csv --schema=13 --domain=campbellsoup.com --sender-email=jeremy_snapp@campbellsoup.com --date-format=%m/%d/%Y --invite=false 
# bin/rails r lib/company_import.rb --file=tmp/century.csv --schema=11 --domain=centurylighting.com --sender-email=aly@centurylighting.com --date-format=%m/%d/%Y --invite=false --birthday-format=%m/%d/%Y
# bin/rails r lib/company_import.rb --file=tmp/cityofallen.csv --schema=11 --domain=cityofallen.org --sender-email=rvice@cityofallen.org --date-format=%m/%d/%y --invite=false 
# bin/rails r lib/company_import.rb --file=tmp/goodway.csv --schema=11 --domain=goodwaygroup.com --sender-email=jzemp@goodwaygroup.com --date-format=%m/%d/%y --invite=false --remove-users=true
# bin/rails r lib/company_import.rb --file=tmp/visions.csv --schema=11 --domain=visionsfcu.org --sender-email=jrosenberg@visionsfcu.org --date-format=%m/%d/%Y --invite=false --birthday-format=%m/%d/%Y --remove-users=true
# bin/rails r lib/company_import.rb --file=tmp/bethanie.csv --schema=11 --domain=bethanie.com.au --sender-email=niamh.ohara@bethanie.com.au --date-format=%m/%d/%y --invite=false --birthday-format=%d-%b
# bin/rails r lib/company_import.rb --file=tmp/cityofallen-201705.csv --schema=14 --domain=cityofallen.org --sender-email=rvice@cityofallen.org --remove-users=true --invite=false
# bin/rails r lib/company_import.rb --file=tmp/healthtronics.csv --schema=11 --domain=healthtronics.com --sender-email=jose.martinez@healthtronics.com --date-format=%m/%d/%Y --invite=false --birthday-format=%m/%d
# bin/rails r lib/company_import.rb --file=tmp/allegiance.csv --schema=1 --domain=allegiancecu.org --sender-email=Angela.Holland@allegiancecu.org --date-format=%m/%d/%Y --invite=false --birthday-format=%m/%d --remove-users=true
# bin/rails r lib/company_import.rb --file=tmp/cityofallen.csv --schema=14 --domain=cityofallen.org --sender-email=rvice@cityofallen.org --remove-users=true --invite=false
# bin/rails r lib/company_import.rb --file=tmp/dealogic.csv --schema=11 --domain=dealogic.com --sender-email=meera.bhudia@dealogic.com --date-format=%m/%d/%Y --invite=false
# bin/rails r lib/company_import.rb --file=tmp/bcbsri.csv --schema=11 --domain=bcbsri.org --sender-email=Stephanie.Huckel@bcbsri.org --date-format=%m/%d/%Y --invite=false

# To send out invites for a company that was imported with --invite=false
# c = Company.where(domain: "investorsgroup.com-Marketing.not.real.tld").first
# sender = User.where(first_name: "Trevor", last_name: "Hubert").first
# c.resend_invitations!(sender)

require 'optparse'
opts = {}

parser = OptionParser.new do |options|
  options.on '-f', '--file FILE', 'CSV file with data to import' do |arg|
    opts[:file] = arg
  end
  options.on '-d', '--domain DOMAIN', 'domain of the company to import into' do |arg|
    opts[:domain] = arg
  end
  options.on '-e', '--sender-email SENDER_EMAIL', 'sender email that be used to invite and make teams' do |arg|
    opts[:sender_email] = arg
  end
  options.on '-t', '--date-format DATE_FORMAT', 'format of dates in the import file' do |arg|
    opts[:date_format] = arg
  end
  options.on '-b', '--birthday-format BIRTHDAY_FORMAT', 'format of birthday dates in the import file' do |arg|
    opts[:birthday_format] = arg
  end
  options.on '-s', '--schema SCHEMA', 'schema format of input csv file' do |arg|
    opts[:schema] = arg
  end
  options.on '-i', '--invite INVITE', 'add and send invite. Default: true; If false, just adds user and marks user has not been invited so we can send invites at later date' do |arg|
    opts[:invite] = arg
  end
  options.on '-u', '--update-only UPDATE', 'dont add users, update attributes of found users only. Default: false.' do |arg|
    opts[:update_only] = arg
  end
  options.on '-x', '--extra-data FILE', 'File to pull confidential data from.' do |arg|
    opts[:extra_data] = arg
  end
  options.on '-r', '--role-delim DELIM', 'delimiter for roles.' do |arg|
    opts[:role_delim] = arg
  end
  options.on '-z', '--remove-users REMOVE', 'Remove users not present in csv.' do |arg|
    opts[:remove_users] = arg
  end

end

parser.parse! ARGV

file = opts[:file] || "tmp/goodway.csv"
domain = opts[:domain] || "goodwaygroup.com"
sender_email = opts[:sender_email] || "jpettijohn@goodwaygroup.com"
# twodigityear = true
date_format = opts[:date_format] || "%m/%d/%y"
birthday_format = opts[:birthday_format] ||  "%m/%d"
schema = (opts.has_key?(:schema) ? opts[:schema].to_i : 3) - 1
send_invitation = opts.has_key?(:invite) && opts[:invite] == "false"  ? false : true
update_only = opts.has_key?(:update_only) && opts[:update_only] == "true"  ? true : false
role_delimiter = opts.has_key?(:role_delim) ? opts[:role_delim] : ";"
extra_data = opts.has_key?(:extra_data) ? YAML.load_file(opts[:extra_data]) : {}
default_password = extra_data["default_password"]
remove_users = opts.has_key?(:remove_users) ? opts[:remove_users] : false

# [0 , 1,     2,     3,    4,            5,         6,    7,          8,                9           ]
# [EmailAddress,FirstName, LastName]
SCHEMA1 = {
  email: 0,
  first_name: 1,
  last_name: 2,
  job_title: 3,
  team_name: 4,
  start_date: 5,
  birthday: 6
}

SCHEMA2 = {
  team_name: 0,
  first_name: 1,
  last_name: 2,
  start_date: 3,
  job_title: 7
}

SCHEMA3 = {
  first_name: 0,
  last_name: 1,
  email: 2,
  start_date: 3,
  team_name: 4,
  job_title: 5
}

# investorsgroup - HR
SCHEMA4 = {
  email: 0,
  first_name: 1,
  last_name: 2,
  job_title: 3,
  start_date: 4
}

# investorsgroup - Marketing
SCHEMA5 = {
  email: 0,
  first_name: 1,
  last_name: 2,
  job_title: 3,
  team_name: 5,
  start_date: 8
}

# amtwoundcare
SCHEMA6 = {
  email: 0,
  first_name: 1,
  last_name: 2,
  start_date: 8
}

SCHEMA7 = {
  first_name: 0,
  last_name: 1,
  email: 2,
  team_name: 3
}

SCHEMA8 = {
  first_name: 0,
  last_name: 1,
  email: 2,
  job_title: 3
}

SCHEMA9 = {
  email: 0,
  first_name: 1,
  last_name: 2,
  job_title: 3,
  team_name: 4
}

SCHEMA10 = {
  email: 0,
  first_name: 1,
  last_name: 2,
  job_title: 3,
  team_name: 4,
  start_date: 5,
  phone: 6
}

SCHEMA11 = {
  email: 0,
  first_name: 1,
  last_name: 2,
  job_title: 3,
  phone: 4,
  team_name: 5,
  roles: 6,
  start_date: 7,
  birthday: 8,
  manager: 9
}

SCHEMA12 = {
  email: 0,
  first_name: 1,
  last_name: 2,
  manager: 3
}

SCHEMA13 = {
  first_name: 0,
  last_name: 1,
  email: 2, 
  job_title: 3,
  manager: 4
}

SCHEMA14 = {
  email: 0,
  last_name: 1,
  first_name: 2,
  team_name: 3
}

SCHEMAS = [SCHEMA1, SCHEMA2, SCHEMA3, SCHEMA4, SCHEMA5, SCHEMA6, SCHEMA7,SCHEMA8,SCHEMA9,SCHEMA10,SCHEMA11,SCHEMA12,SCHEMA13,SCHEMA14]

SCHEMA= SCHEMAS[schema]

#################################################
# DO NOT EDIT BELOW THIS LINE
#################################################
suffix = Rails.env.production? ? "" : ".not.real.tld"
domain = domain + suffix
sender_email = sender_email + suffix
team_delimiter = ";"
# if on server, do test: `file -i tmp/dealogic.csv`
# if shows: tmp/dealogic.csv: text/plain; charset=utf-8
# use: 
# encoding = "UTF-8:UTF-8"
encoding = "iso-8859-1:UTF-8"
csv_opts = {encoding: encoding} unless ENV['SKIP_ENCODING']

csv = CSV.read(file, csv_opts)
c = Company.where(domain: domain).first
sender = User.where(email: sender_email).first
raise "Could not find sender: #{sender_email}" if sender.blank? && !update_only

failed_entries = []
found_emails = []
users_managers = {}

csv.shift # remove headers
csv.each do |row|
  email = row[SCHEMA[:email]].strip.downcase + suffix if row[SCHEMA[:email]].present?
  first_name = row[SCHEMA[:first_name]].strip if row[SCHEMA[:first_name]].present?
  last_name = row[SCHEMA[:last_name]].strip if row[SCHEMA[:last_name]].present?
  job_title = row[SCHEMA[:job_title]].strip if SCHEMA[:job_title].present? && row[SCHEMA[:job_title]].present?
  team_names = row[SCHEMA[:team_name]].strip if SCHEMA[:team_name].present? && row[SCHEMA[:team_name]].present?
  if team_names
    team_names = team_names.split(team_delimiter).map(&:strip)
  end
  start_date = row[SCHEMA[:start_date]].strip if SCHEMA[:start_date].present? && row[SCHEMA[:start_date]].present?
  phone = row[SCHEMA[:phone]].strip if SCHEMA[:phone].present? && row[SCHEMA[:phone]].present?
  birthday = row[SCHEMA[:birthday]].strip if SCHEMA[:birthday].present? && row[SCHEMA[:birthday]].present?
  roles = row[SCHEMA[:roles]].strip if SCHEMA[:roles].present? && row[SCHEMA[:roles]].present?
  roles = roles.split(role_delimiter).map(&:strip) if roles.present?
  manager_email = row[SCHEMA[:manager]].strip + suffix if SCHEMA[:manager].present? && row[SCHEMA[:manager]].present?
  found_emails  << email

  if start_date.present?
    begin
      # timearr = start_date.split("/")
      # timearr[2] = "20" + timearr[2] if twodigityear
      # start_date = Date.parse("#{timearr[2]}-#{timearr[0]}-#{timearr[1]}")
      start_date = DateTime.strptime("#{start_date} 05:00 PDT", date_format+" %H:%M %Z")
    rescue => e
      debugger
      puts ""
    end
  end


  if birthday.present?
    begin
      if birthday_format == "%m/%d"
        birthday = "#{birthday}/1980"
        bformat = "%m/%d/%Y"

      elsif birthday_format == "%m/%d/%Y"
        bformat = "%m/%d/%Y"
        birthday = "#{birthday.slice(0..birthday.rindex("/")-1)}/1980"

      elsif birthday_format == "%d/%m/%Y"
        bformat = "%d/%m/%Y"
        birthday = "#{birthday.slice(0..birthday.rindex("/")-1)}/1980"

      elsif birthday_format == "%d/%m"
        bformat = "%d/%m/%Y"
        birthday = "#{birthday}/1980"
      elsif birthday_format == "%d-%b"
        bformat = "%d-%b-%Y"
        birthday = "#{birthday}-1980"

      end

      birthday = DateTime.strptime("#{birthday} 05:00 PDT", bformat+" %H:%M %Z")
    rescue => e
      debugger
      puts ""
    end
  end

  if team_names.present?
    team_names.each do |team_name|
      team = c.teams.where(name: team_name).first_or_initialize
      if team.new_record?
        team.created_by_id = sender.id
        team.save
      end
    end
  end

  if email.present?
    user = User.where(email: email, network: domain).first
    puts "Finding user by email: #{email}"
  end

  if user.blank?
    puts "User not found"
    if update_only
      puts "User not found: #{email}"
      puts "Skipping since update only"
      next
    else
      if email.blank? 
        failed_entries << row
        next
      else 
        opts = {}
        if send_invitation
          puts "Inviting user by email: #{email}"
          user = sender.invite!(email, nil, company: c, skip_same_domain_check: true, bypass_disable_signups: true)
          user = user.first
        else
          puts "Adding user without invite: #{email}"
          user = sender.add_user_without_invite!(email, company: c)
        end

        # user is always added to network of their domain
        # so move to specified domain if necessary
        unless user.persisted?
          begin
            user.save!
          rescue => e
            debugger
            puts ""
          end
        end

        # if user.network != c.domain
        #   puts "Moving user from #{user.network} to #{c.domain}"
        #   user.move_company_to!(c) 
        # end

      end
    end
  end

  if team_names.present? 
    team_names.each do |team_name|
      team = c.teams.where(name: team_name).first
      if team.users.include?(user)
        puts "User: #{user.email} already on team: #{team.name}"
      else
        puts "Adding #{user.email} to #{team.name}"
        team.users << user
      end
    end
  else
    puts "User: #{user.email} has no team name to be assigned"
  end

  if roles.present?
    puts "Adding #{roles.length} roles to user"

    roles.each do |role_name|
      # ensure company has role setup
      # before adding to user
      company_role = c.company_roles.find_by(name: role_name)
      unless company_role
        puts "Role: #{role_name} doesn't exist...creating..."
        company_role = c.company_roles.create!(name: role_name)
      end
      
      puts "Adding role #{role_name} to user"    
      user.company_roles.add(company_role)
    end
  end

  attrs = {}
  attrs[:job_title] = job_title.humanize if job_title.present?
  attrs[:start_date] = start_date if start_date.present?
  attrs[:first_name] = first_name.humanize if first_name.present?
  attrs[:last_name] = last_name.humanize if last_name.present?
  attrs[:phone] = phone if phone.present?
  attrs[:birthday] = birthday if birthday.present?

  # attrs[:company_id] = c.id
  # attrs[:network] = c.domain
  begin
    if user.disabled?
      user.status = :pending_invite 
      user.disabled_at = nil
    end
    user.assign_attributes(attrs)
    users_managers[user.email] = manager_email if manager_email.present?
  rescue => e
    debugger; puts ""
  end

  if user.changed?
    puts "Making the following changes: #{user.changes.inspect}"
    result = user.save
    puts "===> User was #{'not ' unless result}saved #{'because ' + user.errors.full_messages.join(' ') unless result}"
  else
    puts "There were no changes to make"
  end
  # separate out password from main attribute update to 
  # allow updating of attributes even if password is already
  # set which will cause update to fail(b/c need to include original pw)
  if default_password
    puts "Setting password..."
    user.password = default_password
    result = user.save
    if result
      user.verify_and_activate!
      puts "Password saved and user activated"
    else
      puts "Password could not be saved because #{user.errors.full_messages.join(' ')}"
    end
  end  
end

#process managers
puts "Assigning managers"
unfound_managers = []
users_managers.each do |user_email, manager_email|
  user = User.find_by(email: user_email)
  manager = User.find_by(email: manager_email)
  puts "#{user_email} being assigned to #{manager_email}"
  if manager
    user.update_column(:manager_id, manager.id)
  else
    unfound_managers << manager_email
    puts "MANAGER NOT FOUND: #{manager_email}"
  end
end
unfound_managers = unfound_managers.uniq.sort

if remove_users
  users2delete = c.users.where.not(email: found_emails)
  puts "Removing #{users2delete.length} users not found in spreadsheet"
  users2delete.each do |user|
    puts "Removing: #{user.email}"
    user.destroy
  end

end

if unfound_managers.present?
  puts "-------------------------------------"
  puts "Could not add managers with the following emails: "
  unfound_managers.each do |email|
    puts email
  end
end

if failed_entries.present?
  puts "-------------------------------------"
  puts "Could not process the following rows: "
  failed_entries.each do |failure|
    puts failure.inspect
  end
else
  puts "Import Complete: processed #{csv.length} rows"
end



