class RenameCounterCacheNames < ActiveRecord::Migration[4.2]
  def change
    rename_column :companies, :user_count, :users_count
    rename_column :companies, :recognition_count, :recognitions_count
  end
end
