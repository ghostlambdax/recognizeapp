class AddDeletedAtToSubscriptions < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :deleted_at, :datetime
  end
end
