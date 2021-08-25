require File.join(Rails.root, 'db/merge_users')
suffix = Rails.env.development? ? ".not.real.tld" : ""
c = Company.where(domain: "balfourbeattyus.com"+suffix).first
# sender = c.users.where(email: 'estenman@balfourbeattyus.com'+suffix).first
# badge = c.company_badges.where(short_name: "Welcome").first
# message = "Welcome to Kudos! Let’s kick off the program by sending your first Kudos, today!"
# data = c.users.not_disabled.map do |u| 
#   result = sender.recognize!(u, badge, message, is_private: true, from_bulk: true) rescue 'failed'
#   [u, result] 
# end

# Badge image script
# imgs = Dir["/home/ec2-user/sites/recognizeapp.com/current/public/kudos/*.png"]
# data = imgs.map do |img|
#   basename = File.basename(img)
#   remote_path = "https://recognizeapp.com/kudos/#{basename}"
#   yos = basename.split(" - ").last.gsub(".png",'')
#   yos = yos.gsub(/^0/,'') if yos.to_i >= 10
#   template_id = "year_#{yos}"
#   badge = c.badges.where(anniversary_template_id: template_id).first
#   badge.remote_image_url = remote_path
#   badge.save
#   [basename, remote_path, yos, template_id, badge.try(:id)]
# end

# Account resolution for employees who don't have employee id
# CSV FIELDS: 
#   0: Employee id,
#   1: Email (CURRENT),
#   2: First name,
#   3: Last name,
#   4: Job title,
#   5: Phone,
#   6: Team,
#   7: Roles,
#   8: Start date,
#   9: Birthday,
#   10: Manager Email (CURRENT),
#   11: Email (CORRECTED),
#   12: Manager Email (CORRECTED),
#   13: EmailMatch,
#   14: MgrEmailMatch
csv = CSV.readlines(File.join(Rails.root, "tmp/balfour.csv"))

csv.shift 
data_by_employee_id = {}
data_by_current_email = {}
data_by_correct_email = {}

csv.each do |row|
  employee_id = row[0]
  current_email = row[1].downcase+suffix
  correct_email = row[11].downcase+suffix
  current_email_in_recognize = User.where(email: current_email).exists?
  correct_email_in_recognize = User.where(email: correct_email).exists?

  use_case = case 
  when !current_email_in_recognize && !correct_email_in_recognize
    :neither_in_recognize
  when current_email_in_recognize && !correct_email_in_recognize
    :current_email_in_recognize_correct_email_not_in_recognize
  when !current_email_in_recognize && correct_email_in_recognize
    :current_email_not_in_recognize_correct_email_is_in_recognize
  when current_email_in_recognize && correct_email_in_recognize
    :both_in_recognize
  else
    :unhandled
  end

  packet = {
    employee_id: employee_id, 
    current_email: current_email, 
    correct_email: correct_email,
    current_email_in_recognize: current_email_in_recognize,
    correct_email_in_recognize: correct_email_in_recognize,
    use_case: use_case
  }

  data_by_employee_id[employee_id] = packet
  data_by_current_email[current_email] = packet
  data_by_correct_email[correct_email] = packet
end

# users_without_employee_id = c.users.where(employee_id: nil)
# unfound_users = []
# users_without_employee_id.each do |user|
#   packet = data_by_correct_email[user.email.downcase]
#   unless packet.present?
#     puts "Packet not found for #{user.email}"
#     unfound_users << user
#   else

#   end
# end

# data_by_employee_id.values.map{|h| h[:use_case]}.uniq
# => [:current_email_in_recognize_correct_email_not_in_recognize, :both_in_recognize]
# So only handling those two use cases

data_by_employee_id.each do |employee_id, packet|  
  current_email = packet[:current_email]
  correct_email = packet[:correct_email]
  use_case = packet[:use_case]

  Rails.logger.debug "Handling(#{employee_id}): #{current_email}(current) - #{correct_email}(correct) - #{use_case}"

  if use_case == :both_in_recognize
    # # merge accounts
    # old_user = User.where(email: current_email).first
    # proper_user = User.where(email: correct_email).first
    # move_user_records(old_user, proper_user)
    # old_user.update_column(:employee_id, nil)
    # old_user.really_destroy!
    # proper_user.update_column(:employee_id, employee_id)

  else # current_email_in_recognize_correct_email_not_in_recognize
    # just update
    user = User.where(email: current_email).first
    user.email = correct_email
    user.employee_id = employee_id
    user.save(validate: false)
  end

end