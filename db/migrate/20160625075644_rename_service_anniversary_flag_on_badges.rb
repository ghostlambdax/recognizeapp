class RenameServiceAnniversaryFlagOnBadges < ActiveRecord::Migration[4.2]
  def change
    rename_column :badges, :is_service_anniversary, :is_anniversary
  end
end
