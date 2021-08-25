class AddSettingForHidingProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :private_user_profiles, :boolean, default: false
  end
end
