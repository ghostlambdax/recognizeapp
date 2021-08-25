class AddCustomBadgesEnabledFlagToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :custom_badges_enabled_at, :datetime
  end
end
