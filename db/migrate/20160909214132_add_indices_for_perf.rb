class AddIndicesForPerf < ActiveRecord::Migration[4.2]
  def change
    add_index :companies, [:deleted_at, :parent_company_id]
    add_index :users, [:deleted_at, :email]
    add_index :recognitions, [:deleted_at, :sender_company_id]
    add_index :recognition_recipients, [:deleted_at, :recipient_company_id], name: :rr_del_rcompany_id
  end
end
