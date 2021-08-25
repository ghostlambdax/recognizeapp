class AddTableForDailyCompanyStats < ActiveRecord::Migration[5.0]
  def change
    create_table :daily_company_stats do |table|
      table.column :company_id, :integer, required: true, index: true, unique: true
      table.column :team_id, :integer, index: true, unique: true
      table.column :date, :date, required: true, index: true
      table.column :total_users, :integer, required: true
      table.column :pending_users, :integer, required: true
      table.column :active_users, :integer, required: true
      table.column :disabled_users, :integer, required: true
      table.column :monthly_recipient_res, :float, required: true
      table.column :monthly_sender_res, :float, required: true
      table.column :quarterly_recipient_res, :float, required: true
      table.column :quarterly_sender_res, :float, required: true
      table.column :yearly_recipient_res, :float, required: true
      table.column :yearly_sender_res, :float, required: true
    end
  end
end
