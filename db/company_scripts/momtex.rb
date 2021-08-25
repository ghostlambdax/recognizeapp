emails = %w(bgordon@momtex.com twillis@momtex.com abandoy@momtex.com lburris@momtex.com egarcia@momtex.com kxiong@momtex.com kjohns@momtex.com kjackson@momtex.com msmith@momtex.com lhambrecht@momtex.com khilt@momtex.com jlalim@momtex.com jcameron@momtex.com khuynh@momtex.com jkritzeck@momtex.com kwebster@momtex.com dschechter@momtex.com jalexandre@momtex.com dgreene@momtex.com rbowman@momtex.com dswagler@momtex.com kgowdy@momtex.com ewilson@momtex.com acampbell@momtex.com scarcamo@momtex.com bkendrick@momtex.com ysilva@momtex.com kward@momtex.com dwalton@momtex.com rveljkovic@momtex.com lross@momtex.com aczyzewski@momtex.com ccanon@momtex.com Mwiss@momtex.com hmccaslin@momtex.com snelson@momtex.com trogersmarkle@momtex.com jmojena@momtex.com dwilson@momtex.com amaiellano@momtex.com mlovelace@momtex.com ggrady@momtex.com lbushell@momtex.com tmollison@momtex.com emoser@momtex.com kzastrow@momtex.com mturner@momtex.com kmarshall@momtex.com janders@momtex.com Jlang@momtex.com smcgowan@momtex.com skeels@momtex.com msharkey@momtex.com cstone@momtex.com hlloyd@momtex.com)

suffix = Rails.env.development? ? ".not.real.tld" : ""
emails = emails.map{|e| e+suffix}
users = User.where(email: emails)
company = Company.where(domain: "momtex.com"+suffix).first
anniversary_badges = company.badges.anniversary.where.not(anniversary_template_id: "00_birthday")
data = users.inject({}) do |hash, user|
  hash[user.id] = {user: user}
  hash[user.id][:pa_set] = user.point_activities.where(point_activities: {activity_type: "recognition_recipient"}).where(badge_id: anniversary_badges.map(&:id))
  hash
end
data.each do |user_id,v|
  user = v[:user]
  pa = v[:pa_set].first
  Rails.logger.debug "MOMTEX: #{user_id} - #{v}"
  Rails.logger.debug "MOMTEX2: #{user.email} - updating pa(#{pa.id}) from #{pa.amount} to 2000"
  pa.update_column(:amount, 2000)
end