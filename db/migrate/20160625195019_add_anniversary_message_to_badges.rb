class AddAnniversaryMessageToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :anniversary_message, :text
  end
end
