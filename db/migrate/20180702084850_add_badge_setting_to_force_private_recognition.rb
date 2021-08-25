class AddBadgeSettingToForcePrivateRecognition < ActiveRecord::Migration[5.0]
  def change
    add_column :badges, :force_private_recognition, :boolean, default: false
  end
end
