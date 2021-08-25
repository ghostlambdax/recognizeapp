class MakeCountersOnCompanyHaveDefaultZero < ActiveRecord::Migration[4.2]
  def up
    change_column :companies, :received_recognitions_count, :integer, default: 0
    change_column :companies, :received_user_recognitions_count, :integer, default: 0
  end

  def down
    change_column :companies, :received_recognitions_count, :integer, default: nil
    change_column :companies, :received_user_recognitions_count, :integer, default: nil
  end
end
