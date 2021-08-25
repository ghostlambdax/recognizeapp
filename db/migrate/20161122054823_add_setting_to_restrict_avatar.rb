class AddSettingToRestrictAvatar < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :restrict_avatar_access, :boolean, default: false
  end
end
