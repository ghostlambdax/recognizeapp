class AddDeletedAtIndexToUsersAndRecognitions < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :deleted_at
    add_index :recognitions, :deleted_at
  end
end
