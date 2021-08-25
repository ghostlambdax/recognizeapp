class ChangePrecisionOnDecimal < ActiveRecord::Migration[4.2]
  def up
  	change_column :subscriptions, :amount, :decimal, precision: 8, scale: 2
  end

  def down
  	change_column :subscriptions, :amount, :decimal
  end
end
