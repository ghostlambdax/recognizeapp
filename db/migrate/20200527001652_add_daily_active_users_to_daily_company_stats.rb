class AddDailyActiveUsersToDailyCompanyStats < ActiveRecord::Migration[5.0]
  def change
    [:daily_active_users, :weekly_active_users, :monthly_active_users, :quarterly_active_users, :yearly_active_users].each do |col|
      add_column :daily_company_stats, col, :integer
    end
  end
end
