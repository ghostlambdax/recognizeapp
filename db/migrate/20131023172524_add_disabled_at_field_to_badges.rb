class AddDisabledAtFieldToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :disabled_at, :datetime
  end
end
