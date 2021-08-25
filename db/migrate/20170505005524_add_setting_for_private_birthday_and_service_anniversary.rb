class AddSettingForPrivateBirthdayAndServiceAnniversary < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :receive_birthday_recognitions_privately, :boolean, default: false
    add_column :users, :receive_anniversary_recognitions_privately, :boolean, default: false
  end
end
