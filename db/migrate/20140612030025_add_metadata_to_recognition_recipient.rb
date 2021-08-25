class AddMetadataToRecognitionRecipient < ActiveRecord::Migration[4.2]
  def change
    add_column :recognition_recipients, :metadata, :text, limit: 4294967295
  end
end
