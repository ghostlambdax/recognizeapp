class ChangeArchivedDefaultOnSubscriptions < ActiveRecord::Migration[4.2]
  def change
    change_column :subscriptions, :archived, :boolean, default: false
  end
end
