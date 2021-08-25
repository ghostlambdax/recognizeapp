class SettingForInviteViewToggle < ActiveRecord::Migration[4.2]
  def up
    add_column :companies, :allow_invite, :boolean, default: true
  end

  def down

  end
end
