class MigrateDataFromBadgeLongNameToDescription < ActiveRecord::Migration[4.2]
  def up
    Badge.update_all("long_description = long_name")
  end
end
