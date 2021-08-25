class AddAllowAdminDashboardFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_admin_dashboard, :boolean, default: false
  end
end
