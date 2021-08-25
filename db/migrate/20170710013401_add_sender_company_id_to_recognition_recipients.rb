class AddSenderCompanyIdToRecognitionRecipients < ActiveRecord::Migration[4.2]
  def change
    add_column :recognition_recipients, :sender_company_id, :integer
    add_index :recognition_recipients, :sender_company_id
    add_index :recognition_recipients, [:sender_company_id, :recipient_company_id], name: :rrscorco
    add_index :recognition_recipients, [:deleted_at, :sender_company_id], name: :rrdelsco
    add_index :recognition_recipients, [:deleted_at, :sender_company_id, :recipient_company_id], name: :rrdelscorco
  end
end
