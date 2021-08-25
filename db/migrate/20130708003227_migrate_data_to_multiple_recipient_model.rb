class MigrateDataToMultipleRecipientModel < ActiveRecord::Migration[4.2]
  def up
    Recognition.where(nil).each do |r|
#      recipient = User.find(r.recipient_id)
#      r.recipients = [recipient]
#      r.save
      RecognitionRecipient.create!(recognition: r, recipient_type: "User", recipient_id: r.recipient_id)
    end
  end

  def down
  end
end
