class AddStatusIndicesToUsers < ActiveRecord::Migration[5.0]
  def change
    add_index :users, [:company_id, :status, :deleted_at], name: :company_status
  end
end
