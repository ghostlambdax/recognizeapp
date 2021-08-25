data = UserTeam.joins(:user, :team).includes(:user, :team).where("users.company_id <> teams.company_id")
puts "Fixing #{data.length} user teams"
data.each do |ut|
  user = ut.user
  wrong_team = ut.team
  right_team = user.company.teams.where(name: wrong_team.name).first

  puts "User: #{user.email}"
  puts "Wrong Team: #{wrong_team.name} (#{wrong_team.company.domain}(#{wrong_team.company_id}))"
  puts "Right Team: #{right_team.name} (#{right_team.company.domain}(#{right_team.company_id}))"

  ut.update_column(:team_id, right_team.id)
  user.update_all_points!
  wrong_team.update_all_points!
  right_team.update_all_points!
end

data_now = UserTeam.joins(:user, :team).includes(:user, :team).where("users.company_id <> teams.company_id")
puts "Now there are #{data_now.length} wrong records"