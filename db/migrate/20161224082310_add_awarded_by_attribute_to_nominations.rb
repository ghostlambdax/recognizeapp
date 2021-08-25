class AddAwardedByAttributeToNominations < ActiveRecord::Migration[4.2]
  def change
    add_column :nominations, :awarded_by_id, :integer
  end
end
