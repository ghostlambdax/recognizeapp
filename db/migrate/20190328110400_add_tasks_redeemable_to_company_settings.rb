class AddTasksRedeemableToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :tasks_redeemable, :boolean, default: true

    CompanySetting.reset_column_information
    CompanySetting.update_all(tasks_redeemable: false)
  end
end
