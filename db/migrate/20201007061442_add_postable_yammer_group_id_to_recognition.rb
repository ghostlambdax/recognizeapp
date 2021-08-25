class AddPostableYammerGroupIdToRecognition < ActiveRecord::Migration[5.0]
  def change
    add_column :recognitions, :post_to_yammer_group_id, :string, default: nil
  end
end
