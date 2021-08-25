class AddContactsFieldToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :contacts, :text, limit: 4294967295
  end
end
