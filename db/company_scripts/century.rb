suffix = Rails.env.development? ? ".not.real.tld" : ""
c = Company.where(domain: "centurylighting.com#{suffix}").first
company_roles = CompanyRole.where(company_id: c.id)
reward_manager = User.where(company_id: c.id, email: "aly@centurylighting.com#{suffix}").first

rows = CSV.readlines("tmp/century-badges.csv")
rows.shift
  
rows.each do |row|
  puts "Badge Row: #{row}"
  # start disabled until we find out about roles
  b = Badge.where(company_id: c.id, name: "centurylighting-#{row[0]}").first_or_initialize
  b.assign_attributes(
    short_name: row[0], 
    sending_frequency: row[2],
    sending_interval_id: Interval.monthly.to_i,
    points: row[4],
    image: Rails.root.join("public/century/#{row[6]}.png").open,
    disabled_at: Time.now)

  new_roles = company_roles.detect{|cr| cr.name == row[1]}

  Badge.transaction do
    b.save!
    if row[1] != "Employees"
      b.grant_permission_to_roles(:send, [new_roles])
    end
  end
end

rows = CSV.readlines("tmp/century-rewards.csv")
rows.shift

rows.each do |row|
  puts "Reward row: #{row}"
  reward = Reward.where(company_id: c.id, title: row[0]).first_or_initialize
  case row[3].to_f
  when 0.08
    interval = Interval.yearly
  when 0.04
    interval = Interval.quarterly
  else
    interval = Interval.monthly
  end

  reward.assign_attributes(
    description: row[6],
    points: row[2],
    quantity_interval_id: interval.to_i,
    quantity: 1,
    manager_id: reward_manager.id
  )
  reward.save!
end

