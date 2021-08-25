class AddTimezoneToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :timezone, :string

    CompanySetting.update_all(timezone:  Rails.application.config.time_zone)
  end
end
