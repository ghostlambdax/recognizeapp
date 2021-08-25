class AddAdditionalInstructionsToRewards < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :additional_instructions, :text,  limit: 4294967295
  end
end
