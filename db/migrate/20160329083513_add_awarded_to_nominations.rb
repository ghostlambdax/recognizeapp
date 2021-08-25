class AddAwardedToNominations < ActiveRecord::Migration[4.2]
  def change
    add_column :nominations, :awarded, :boolean
  end
end
