class AddPrimaryFlagToFundsAccount < ActiveRecord::Migration[4.2]
  def change
    add_column :funds_accounts, :is_primary, :boolean, default: false
  end
end
