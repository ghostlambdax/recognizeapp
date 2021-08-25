class AddRedeemableBooleansToCompanySetting < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :sent_recognition_redeemable, :boolean, default: true
    add_column :company_settings, :received_approval_redeemable, :boolean, default: true
    add_column :company_settings, :sent_approval_redeemable, :boolean, default: true

    CompanySetting.reset_column_information
    CompanySetting.update_all(
      sent_recognition_redeemable: false, 
      received_approval_redeemable: false,
      sent_approval_redeemable: false
    )
  end
end
