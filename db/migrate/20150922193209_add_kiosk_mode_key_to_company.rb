class AddKioskModeKeyToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :kiosk_mode_key, :string
  end
end
