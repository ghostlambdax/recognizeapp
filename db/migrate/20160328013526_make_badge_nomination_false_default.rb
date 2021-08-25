class MakeBadgeNominationFalseDefault < ActiveRecord::Migration[4.2]
  def up
    change_column :badges, :is_nomination, :boolean, default: false
  end

  def down
    change_column :badges, :is_nomination, :boolean, default: nil
  end
end
