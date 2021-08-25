class MigrateRecognitionRecipientSenderCompanyData < ActiveRecord::Migration[4.2]
  def up

    recognition_recipients = RecognitionRecipient.joins(:recognition).select('recognition_recipients.id, recognitions.sender_company_id')
    count = recognition_recipients.length
    recognition_recipients.each_with_index do |rr, index|
      puts "Updating recognition recipient with sender company id #{index}/#{count}"
      rr.update_column(:sender_company_id, rr.sender_company_id)
    end
  end
end
