class AddNewCommentEmailNotificationSetting < ActiveRecord::Migration[4.2]
  def up
    add_column :email_settings, :new_comment, :boolean, default: true
  end

  def down
  end
end
