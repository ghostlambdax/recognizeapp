#
# Anniversary Fixer
#   Lists users ids with missing birthday / anniversary recognitions since Feb 3rd, 2019,
#   optionally sending those recognitions
#
# Usage: (from project root directory)
#   bin/rails r db/company_scripts/anniversary_fixer.rb [-s]

require 'optparse'

opts = {}
OptionParser.new do |parser|
  parser.on '-s', '--send-recognitions', 'Send missing anniversary / birthday recognitions.' do |arg|
    opts[:send_recognitions] = arg
  end
end.parse!

def get_people_who_should_have_been_recognized(date_range)
  { anniversary: [], birthday: [] }.tap do |users|
    # companies = Company.program_enabled
    # companies = Company.where(domain: "bassett.org")
    companies = [] # be safe for now, next time check date range, company and whether to send both anniv and birthday recognitions
    date_range.each do |day|
      print "#{day.mday}#{', ' unless day == date_range.end}"
      Timecop.freeze(day) do
        companies.each do |company|
          ar = Anniversary::Recognizer.new(company)
          users[:anniversary].push(*ar.send(:users_who_have_service_anniversaries_today))
          users[:birthday].push(*ar.send(:users_who_have_birthdays_today))
        end
      end
    end
  end
end

def filter_users_who_didnt_receive_recognition(type, users, date_range)
  users.reject do |u|
    company = u.company
    badge = if type == :birthday
              template_id = Badge::BIRTHDAY_TEMPLATE_ID
              company.badges.anniversary.where(anniversary_template_id: template_id)
            else # anniversary
              ar = Anniversary::Recognizer.new(company)
              ar.detect_service_anniversary_badge(ar.service_anniversary_badges, u.start_date)
            end

    if badge
      Recognition
        .joins(:recognition_recipients)
        .where(badge: badge, created_at: date_range, recognition_recipients: { user: u })
        .exists?
    else # unexpected case
      puts "Badge not found, skipping user (type: #{type}, user_id: #{u.id}, company: #{company.domain})"
      true # reject user
    end
  end
end

def send_anniversary_recognitions(users_hash)
  users_hash[:anniversary].each do |u|
    ar = Anniversary::Recognizer.new(u.company)
    ar.recognize_service_anniversary(u, ar.service_anniversary_badges)
  end

  # users_hash[:birthday].each do |u|
  #   ar = Anniversary::Recognizer.new(u.company)
  #   ar.recognize_birthday(u, ar.birthday_badge)
  # end
end

# BEGIN script flow #

# TODO: what about time zone here?
date_range = Time.parse("February 3rd, 2019").to_date..Time.now.to_date
datetime_range = Time.parse("February 3rd, 2019").beginning_of_day..Time.now.end_of_day

# Part 1 - finding users who should have been recognized
print "Checking for Date (Feb 2019):"
people_who_should_have_been_recognized = get_people_who_should_have_been_recognized(date_range)
puts "\n\npeople who should have been recognized: (user ids)"
people_who_should_have_been_recognized.map do |type, users|
  puts "  #{type}:", "  #{users.map(&:id)}"
end

# Part 2 - filtering users from part 1 who have not been recognized
people_who_have_not_been_recognized = {}
people_who_should_have_been_recognized.each do |type, users|
  people_who_have_not_been_recognized[type] = filter_users_who_didnt_receive_recognition(type, users, datetime_range)
end

puts "\npeople who have not been recognized: (user ids)"
if people_who_have_not_been_recognized == people_who_should_have_been_recognized
  puts '  same as above'
else
  filename = "anniversary-fixes.pdf"
  # CSV.open(filename, 'wb') do |csv|
    people_who_have_not_been_recognized.map do |type, users|
      type_method = type == :birthday ? :birthday : :start_date
      privacy_method = type == :birthday ? :receive_birthday_recognitions_privately : :receive_anniversary_recognitions_privately
      puts "  #{type}:"
      users.each {|u| 
        arr = [u.company.domain, u.id, u.email, type, u.send(type_method), u.send(privacy_method) ? "private" : ""]
        puts arr.join(",")
        # csv << arr
      }
    # end
  end

  # c = Company.first
  # cc = c.customizations
  # cc.end_user_guide = File.open(filename)
  # cc.save
  # puts cc.end_user_guide.url
end

# Part 3 (optional) - sending recognitions to the resulting users
if opts[:send_recognitions]
  puts
  if people_who_have_not_been_recognized.values.any?(&:present?)
    puts "Sending recognitions..."
    send_anniversary_recognitions(people_who_have_not_been_recognized)
  else
    puts 'No Users found with pending anniversary recognitions.'
  end
end

# END script flow #
