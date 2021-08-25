class AddIsCrossCompanyToRecognition < ActiveRecord::Migration[5.0]
  def change
    add_column :recognitions, :is_cross_company, :boolean

    Recognition.reset_column_information
    Recognition
      .joins(:recognition_recipients)
      .where('recognitions.sender_company_id <> recognition_recipients.recipient_company_id')
      .distinct
      .update_all(is_cross_company: true)

    Recognition.where(is_cross_company: nil).update_all(is_cross_company: false)
  end
end
