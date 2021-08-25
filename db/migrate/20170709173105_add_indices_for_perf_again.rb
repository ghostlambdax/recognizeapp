class AddIndicesForPerfAgain < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :manager_id
    add_index :users, [:company_id, :deleted_at]
  end
end
