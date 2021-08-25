class AddBadgeSettingForAllowingSelfNominations < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :allow_self_nomination, :boolean, default: false
  end
end
