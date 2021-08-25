class AddSettingForAllowHallOfFame < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_hall_of_fame, :boolean, default: false
  end
end
