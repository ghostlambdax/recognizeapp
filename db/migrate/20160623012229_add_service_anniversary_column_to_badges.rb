class AddServiceAnniversaryColumnToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :is_service_anniversary, :boolean, default: false
    add_column :companies, :is_service_anniversary_enabled, :boolean, default: false
  end
end
