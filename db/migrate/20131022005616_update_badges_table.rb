class UpdateBadgesTable < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :company_id, :integer
    add_column :badges, :image, :string
    add_index :badges, :company_id
  end
end
