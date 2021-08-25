class AddAwardedAtToNominations < ActiveRecord::Migration[4.2]
  def change
    add_column :nominations, :awarded_at, :datetime
  end
end
