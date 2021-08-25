class AddGlobalPrivacyFlagToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :global_privacy, :boolean, default: false
  end
end
