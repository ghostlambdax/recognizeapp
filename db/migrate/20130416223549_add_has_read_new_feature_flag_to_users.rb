class AddHasReadNewFeatureFlagToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :has_read_features, :text
  end
end
