class AddUsersCompany < ActiveRecord::Migration[4.2]
  def up
    # DEPRECATED this migration since its served its purpose(migrated production data).
    #  - moved it to seeds for developer fresh installs
    # FactoryBot.create(:company, name: "Users", domain: "users")
  end

  def down
  end
end
