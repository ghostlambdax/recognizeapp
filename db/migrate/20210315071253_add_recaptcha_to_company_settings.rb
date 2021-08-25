class AddRecaptchaToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :recaptcha, :boolean, default: true
  end
end
