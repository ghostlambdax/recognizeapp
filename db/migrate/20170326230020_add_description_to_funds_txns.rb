class AddDescriptionToFundsTxns < ActiveRecord::Migration[4.2]
  def change
    add_column :funds_txns, :description, :text
  end
end
