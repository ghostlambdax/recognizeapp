class AddFbWorkplacePostIdToRecognitions < ActiveRecord::Migration[5.0]
  def change
    add_column :recognitions, :fb_workplace_post_id, :string
  end
end
