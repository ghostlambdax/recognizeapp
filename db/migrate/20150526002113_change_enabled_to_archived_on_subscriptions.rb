class ChangeEnabledToArchivedOnSubscriptions < ActiveRecord::Migration[4.2]
  def change
    rename_column :subscriptions, :enabled, :archived
    Subscription.where(archived: true).update_all("archived = !archived")
  end
end
