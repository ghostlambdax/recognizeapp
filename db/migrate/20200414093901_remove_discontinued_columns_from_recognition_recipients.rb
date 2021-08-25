class RemoveDiscontinuedColumnsFromRecognitionRecipients < ActiveRecord::Migration[5.0]
  def change
    remove_index :recognition_recipients,  column: [:recipient_id, :recipient_type]
    remove_column :recognition_recipients, :recipient_type, :string
    remove_column :recognition_recipients, :recipient_id, :integer
    RecognitionRecipient.reset_column_information
  end
end
