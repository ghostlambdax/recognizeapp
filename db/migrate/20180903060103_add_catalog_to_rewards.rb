class AddCatalogToRewards < ActiveRecord::Migration[5.0]
  def change
    add_reference :rewards, :catalog, foreign_key: true
  end
end
