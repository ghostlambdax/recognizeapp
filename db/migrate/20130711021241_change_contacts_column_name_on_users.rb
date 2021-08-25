class ChangeContactsColumnNameOnUsers < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :contacts, :contacts_raw
  end

end
