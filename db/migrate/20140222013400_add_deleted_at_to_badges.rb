class AddDeletedAtToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :deleted_at, :datetime
  end
end
