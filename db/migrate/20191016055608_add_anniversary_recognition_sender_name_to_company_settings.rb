class AddAnniversaryRecognitionSenderNameToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :anniversary_recognition_custom_sender_name, :string
  end
end
