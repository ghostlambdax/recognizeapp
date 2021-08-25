class AddPostToYammerGroupId < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :post_to_yammer_group_id, :string
  end
end
