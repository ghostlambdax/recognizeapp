class AddAllowManagerOfManagerNotificationsToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :allow_manager_of_manager_notifications, :boolean, default: false
  end
end
