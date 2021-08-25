class AddDeletedAtColumnToRecognitionRecipients < ActiveRecord::Migration[4.2]
  def change
    add_column :recognition_recipients, :deleted_at, :datetime
  end
end
