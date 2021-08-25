# require File.join(Rails.root, 'db/merge_users')

suffix = Rails.env.development? ? ".not.real.tld" : ""
c = Company.where(domain: "corvallisclinic.com#{suffix}").first

rows = CSV.readlines("tmp/corvallisrewards2.csv")
rows.shift


# u1, u2 = *c.users.where(first_name: "Krista", last_name: "Bass")
# move_user_records(u1, u2)
# u1.destroy(deep_destroy: true)

# u1, u2 = *c.users.where(first_name: "Michelle", last_name: "Holland")
# move_user_records(u1, u2)
# u1.destroy(deep_destroy: true)

# u1, u2 = *c.users.where(first_name: "Jean", last_name: "Mercier")
# move_user_records(u1, u2)
# u1.destroy(deep_destroy: true)
tiers = {
  1 => 20,
  2 => 30,
  3 => 40,
  4 => 50
}

results = []
rows.each do |row|
  puts "Row: #{row}"
  name = row[0]
  email = row[3]+suffix
  points = row[1]
  levels = row[2].split(",").map(&:strip)

  # first, last = name.split(" ").map(&:strip)  
  # users = User.where(company_id: c.id, first_name: first, last_name: last)
  users = User.where(email: email)
  raise "User not found" if users.length == 0
  raise "Too many users" if users.length > 1
  u = users.first
  result = {id: u.id, email: u.email, redeemable_before: u.redeemable_points, trying_to_redeem: 0, redeemable_after: u.redeemable_points}

  puts "User: #{u.id} - #{u.email}"
  puts "Levels: #{levels}"
  levels.each do |level|

    reward = c.rewards.where(title: "Tier #{level}").first
    variant = reward.variants.enabled.first
    raise "Reward not found" unless reward
    puts "Redeeming reward: #{reward.title} for #{variant.points} points"
    result[:trying_to_redeem] += variant.points

    # Turn off emails before uncommenting this
    # comment out: 
    #     + after_commit :send_notifications, on: :create
    #     + if result
    #         RedemptionNotifier.delay(queue: 'priority').notify_status_approved(self.user, self)
    #         self.delay(queue: 'priority').publish(:redemption_approved, self)
    #       end
    # Uncomment these:
    # redemption = Redemption.redeem(u, variant)
    # redemption.approve(approver: c.company_admin)
    # result[:redeemable_after] = u.reload.redeemable_points # For live run only
    result[:redeemable_after] -= variant.points # For dry run only
  end
  results << result
end
puts results
puts "====================="
puts results.select{|r| r[:redeemable_after] < 0}