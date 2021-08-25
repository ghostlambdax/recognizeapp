class AddRecognizeAdminToFundsAccount < ActiveRecord::Migration[4.2]
  def change
    add_column :funds_accounts, :recognize_admin, :boolean, null: false, default: false
  end
end
