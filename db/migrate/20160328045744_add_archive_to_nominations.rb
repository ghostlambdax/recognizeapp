class AddArchiveToNominations < ActiveRecord::Migration[4.2]
  def change
    add_column :nominations, :archive, :boolean
  end
end
