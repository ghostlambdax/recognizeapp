 # [113717, "Happy Birthday", Sun, 16 Apr 2017, "MSolowiej@visionsfcu.org", Thu, 01 May 1980, Mon, 16 Apr 2007],
 # [113716, "Happy Birthday", Sun, 16 Apr 2017, "JVerno@visionsfcu.org", Mon, 31 Mar 1980, Mon, 16 Apr 2001],
 # [113683, "Happy Birthday", Sat, 15 Apr 2017, "aperez@visionsfcu.org", Tue, 08 Apr 1980, Mon, 15 Apr 2002],
 # [113682, "Happy Birthday", Sat, 15 Apr 2017, "JRandall@visionsfcu.org", Wed, 16 Apr 1980, Mon, 15 Apr 2013]]

company = Company.where(domain: "visionsfcu.org").first
service_anniversary_badges = company.anniversary_badges.reject{|b| b.disabled? || b.birthday?}
def recognize_service_anniversary(user, service_anniversary_badges)

  years_of_service = Time.now.year - user.start_date.year
  badge = service_anniversary_badges.detect{|sab| sab.anniversary_template_id == "year_#{years_of_service.to_s.rjust(2, '0')}"}
  if badge.present?
    send_anniversary_recognition(user, badge)
  end
end

def send_anniversary_recognition(user, badge)
  User.system_user.recognize!(user, badge, badge.anniversary_message)
end

[113717, 113716, 113683, 113682].each do |id|
  r = Recognition.find(id)
  user = r.user_recipients.first
  if user.start_date.day == 15
    Timecop.freeze(Time.parse("April 15th, 2017"))
  elsif user.start_date.day == 16
    Timecop.freeze(Time.parse("April 16th, 2017"))
  else
    raise "wtf"
  end
  recognize_service_anniversary(user, service_anniversary_badges)
  r.destroy
end

####################################################################

suffix = Rails.env.development? ? ".not.real.tld" : ""
c = Company.where(domain: "visionsfcu.org"+suffix).first
jenna = c.users.active.where(first_name: "Jenna").first
b = c.company_badges.where(short_name: "Welcome To Rewards!").first
c.users.active.where.not(users: {id: jenna.id}).each{|u| puts "Recognizing: #{u.email}"; jenna.recognize!(u.email, b, "Welcome to Rewards!", {is_private: true, from_bulk: true})}

####################################################################
emails = %w(jdobrzynski@visionsfcu.org shennes@visionsfcu.org lopper@visionsfcu.org bsullivan@visionsfcu.org)

recognizer = Anniversary::Recognizer.new(c)
service_anniversary_badges = c.anniversary_badges.reject{|b| b.disabled? || b.birthday?}

emails.each do |email|
  email = email + suffix
  puts "Sending service anniversary badge for: #{email}"
  u = User.where(email: email).first
  u.start_date = u.start_date + 1.year
  recognizer.send(:recognize_service_anniversary, u, service_anniversary_badges)
end

