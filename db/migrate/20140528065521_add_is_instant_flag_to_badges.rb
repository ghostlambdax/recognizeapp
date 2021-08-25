class AddIsInstantFlagToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :is_instant, :boolean, default: false
  end
end
