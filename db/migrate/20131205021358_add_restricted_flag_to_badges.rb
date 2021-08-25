class AddRestrictedFlagToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :restricted, :boolean, default: false
  end
end
