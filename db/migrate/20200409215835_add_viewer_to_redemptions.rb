class AddViewerToRedemptions < ActiveRecord::Migration[5.0]
  def change
    add_column :redemptions, :viewer, :string
    add_column :redemptions, :viewer_description, :string
  end
end
