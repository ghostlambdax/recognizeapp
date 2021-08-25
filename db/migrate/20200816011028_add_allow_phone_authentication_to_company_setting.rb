class AddAllowPhoneAuthenticationToCompanySetting < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :allow_phone_authentication, :boolean, default: false
  end
end
