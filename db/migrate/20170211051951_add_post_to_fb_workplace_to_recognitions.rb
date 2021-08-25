class AddPostToFbWorkplaceToRecognitions < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :post_to_fb_workplace, :boolean, default: false
  end
end
