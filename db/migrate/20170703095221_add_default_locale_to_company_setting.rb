class AddDefaultLocaleToCompanySetting < ActiveRecord::Migration[4.2]
  def change
    add_column(:company_settings, :default_locale, :string, default: 'en')
    add_column(:company_settings, :default_birthday_recognition_privacy, :boolean, default: false)
    add_column(:company_settings, :default_anniversary_recognition_privacy, :boolean, default: false)
  end
end

