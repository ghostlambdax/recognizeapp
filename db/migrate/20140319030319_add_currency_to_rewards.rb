class AddCurrencyToRewards < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :currency, :string
  end
end
