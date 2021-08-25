class AddEmployeeId < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :employee_id, :string
    add_index :users, [:company_id, :employee_id], unique: true
  end
end
