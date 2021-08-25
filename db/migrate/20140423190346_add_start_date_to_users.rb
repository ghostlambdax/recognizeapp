class AddStartDateToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :start_date, :datetime
  end
end
