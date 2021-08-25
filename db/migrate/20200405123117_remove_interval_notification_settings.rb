# Remove unused columns for a long-obsolete feature (unused since 2014)
# Reverts db/migrate/20140809165041_add_interval_notification_settings.rb
class RemoveIntervalNotificationSettings < ActiveRecord::Migration[5.0]
  def change
    remove_column :email_settings, :interval_winner_notifications, :boolean, default: true
    remove_column :companies, :allow_interval_winner_notifications, :boolean, default: true
  end
end
