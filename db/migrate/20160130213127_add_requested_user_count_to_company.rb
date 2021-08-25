class AddRequestedUserCountToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :requested_user_count, :integer
  end
end
