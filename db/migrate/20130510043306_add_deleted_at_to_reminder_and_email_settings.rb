class AddDeletedAtToReminderAndEmailSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :reminders, :deleted_at, :datetime
    add_column :email_settings, :deleted_at, :datetime
  end
end
