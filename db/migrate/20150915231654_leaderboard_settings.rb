class LeaderboardSettings < ActiveRecord::Migration[4.2]
  def change

    add_column :companies, :allow_you_stats, :boolean, default: true
    add_column :companies, :allow_top_employee_stats, :boolean, default: false

  end
end