class AddSettingToLimitRecognitionsToIntraCompanyOnly < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :limit_sending_to_intracompany_only, :boolean, default: false
  end
end
