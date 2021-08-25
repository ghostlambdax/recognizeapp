class AddSettingForRequiredMessage < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :message_is_required, :boolean, default: false
  end
end
