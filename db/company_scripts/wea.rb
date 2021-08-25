suffix = Rails.env.development? ? ".not.real.tld" : ""
c = Company.where(domain: "weatrust.com#{suffix}").first
company_roles = CompanyRole.where(company_id: c.id)

rows = CSV.readlines("tmp/wea-badges.csv")
rows.shift
  
rows.each do |row|
  puts "Badge Row: #{row}"
  # start disabled until we find out about roles
  name = row[0].downcase.strip.gsub('(', '-').gsub(')', '').gsub(' ','')
  image = Rails.root.join("public/wea/#{name}.png").open
  b = Badge.where(company_id: c.id, name: "weatrust-#{name}").first_or_initialize
  b.assign_attributes(
    short_name: row[0], 
    image: image)

  new_roles = company_roles.detect{|cr| cr.name == row[1]}

  Badge.transaction do
    b.save!
    if row[1] != "Employees"
      b.grant_permission_to_roles(:send, [new_roles])
    end
  end
end

# rows = CSV.readlines("tmp/century-rewards.csv")
# rows.shift

# rows.each do |row|
#   puts "Reward row: #{row}"
#   reward = Reward.where(company_id: c.id, title: row[0]).first_or_initialize
#   case row[3].to_f
#   when 0.08
#     interval = Interval.yearly
#   when 0.04
#     interval = Interval.quarterly
#   else
#     interval = Interval.monthly
#   end

#   reward.assign_attributes(
#     description: row[6],
#     points: row[2],
#     quantity_interval_id: interval.to_i,
#     quantity: 1,
#     manager_id: reward_manager.id
#   )
#   reward.save!
# end

