class AddVisibilitySettingToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :show_in_badge_list, :boolean, default: true
  end
end
