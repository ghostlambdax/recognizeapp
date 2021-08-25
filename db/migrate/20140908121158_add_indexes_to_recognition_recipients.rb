class AddIndexesToRecognitionRecipients < ActiveRecord::Migration[4.2]
  def change
    add_index :recognition_recipients, :recipient_company_id
    add_index :recognition_recipients, :recipient_network
  end
end
