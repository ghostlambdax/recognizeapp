class AddIsNominationToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :is_nomination, :boolean
  end
end
