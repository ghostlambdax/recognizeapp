class AddAdditionalInstructionsToRedemptions < ActiveRecord::Migration[4.2]
  def change
    add_column :redemptions, :additional_instructions, :text,  limit: 4294967295
  end
end
