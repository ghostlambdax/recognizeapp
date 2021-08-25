class AddResponseMessageToRedemptions < ActiveRecord::Migration[4.2]
  def change
    add_column :redemptions, :response_message, :text
  end
end
