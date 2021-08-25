class AddPerishableTokenToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :perishable_token, :string, default: "", null: false
  end
end
