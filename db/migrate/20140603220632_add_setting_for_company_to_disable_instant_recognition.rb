class AddSettingForCompanyToDisableInstantRecognition < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_instant_recognition, :boolean, default: true
  end
end
