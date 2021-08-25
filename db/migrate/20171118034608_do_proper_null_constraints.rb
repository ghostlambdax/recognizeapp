class DoProperNullConstraints < ActiveRecord::Migration[4.2]
  def up
    change_column :companies, :sync_enabled, :boolean, default: false, null: false
    change_column :companies, :sync_teams, :boolean, default: false, null: false
    change_column :recognitions, :is_private, :boolean, default: false, null: false
    change_column :companies, :allows_private, :boolean, default: true, null: false    
    change_column :users, :email, :string, null: false
  end

  def down
  end
end
