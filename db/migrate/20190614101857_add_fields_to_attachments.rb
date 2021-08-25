class AddFieldsToAttachments < ActiveRecord::Migration[5.0]
  def change
    add_column :attachments, :company_id, :integer
    add_column :attachments, :requester_id, :integer
    add_column :attachments, :uploader_id, :integer
    add_column :attachments, :original_filename, :string
    add_column :attachments, :description, :text
    add_column :attachments, :requested_at, :datetime

    add_index :attachments, :company_id
  end
end
