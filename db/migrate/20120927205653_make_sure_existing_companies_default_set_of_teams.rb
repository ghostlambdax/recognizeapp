class MakeSureExistingCompaniesDefaultSetOfTeams < ActiveRecord::Migration[4.2]
  def up
    Company.with_deleted.all.each do |c|
      Team.default_set.each do |t|
        c.teams << Team.new(name: t) unless c.has_team?(t)
      end
    end
  end

end
