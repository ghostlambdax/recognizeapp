class UpdateRecognizeAccountToAllowAdminDashboard < ActiveRecord::Migration[4.2]
  def up
    Company.where(domain: "recognizeapp.com").update_all("allow_admin_dashboard = true")
  end

  def down
  end
end
