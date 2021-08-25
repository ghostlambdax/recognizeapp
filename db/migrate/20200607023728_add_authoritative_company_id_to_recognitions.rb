class AddAuthoritativeCompanyIdToRecognitions < ActiveRecord::Migration[5.0]
  def change
    add_column :recognitions, :authoritative_company_id, :integer
    add_index :recognitions, :authoritative_company_id, name: "auth_company"
    add_index :recognitions, [:deleted_at, :authoritative_company_id, :status_id, :is_private], name: "stream_index"
    add_index :recognitions, [:deleted_at, :authoritative_company_id, :status_id, :is_private, :badge_id], name: "status_badge_auth_deleted_company"
  end
end
