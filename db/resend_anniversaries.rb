def send_anniversary_recognition(user, badge)
  User.system_user.recognize!(user, badge, badge.anniversary_message)
end

def resend_anniversary(user)
  company = user.company
  service_anniversary_badges = company.anniversary_badges.reject{|b| b.disabled? || b.birthday?}
  years_of_service = Time.now.year - user.start_date.year
  badge = service_anniversary_badges.detect{|sab| sab.anniversary_template_id == "year_#{years_of_service.to_s.rjust(2, '0')}"}
  if badge.present?
    send_anniversary_recognition(user, badge)
  end  
end

def resend_birthday(user)
  company = user.company
  birthday_badge = company.anniversary_badges.detect{|b| !b.disabled? && b.birthday?}
  if birthday_badge.present?
    send_anniversary_recognition(user, birthday_badge)
  end
end


def doit(anniversary_user_ids, birthday_user_ids)
  anniversaries = User.where(id: anniversary_user_ids)
  birthdays = User.where(id: birthday_user_ids) 

  anniversaries.each do |user|
    resend_anniversary(user)
  end
  birthdays.each do |user|
    resend_birthday(user)
  end

end

# doit([56754, 55384], [61898, 61929])