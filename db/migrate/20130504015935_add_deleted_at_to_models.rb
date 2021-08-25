class AddDeletedAtToModels < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :deleted_at, :datetime
    add_column :users, :deleted_at, :datetime
    add_column :recognitions, :deleted_at, :datetime
    add_column :recognition_approvals, :deleted_at, :datetime
  end
end
