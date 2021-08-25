class AddSettingForAutolinkFbWorkplaceAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :company_settings, :autolink_fb_workplace_accounts, :boolean, default: true
  end
end
