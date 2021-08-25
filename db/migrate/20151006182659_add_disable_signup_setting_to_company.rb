class AddDisableSignupSettingToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :disable_signups, :boolean, default: false
  end
end
