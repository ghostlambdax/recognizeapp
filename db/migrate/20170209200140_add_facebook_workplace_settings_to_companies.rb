class AddFacebookWorkplaceSettingsToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :fb_workplace_community_id, :string
    add_column :companies, :fb_workplace_token, :text
    add_column :companies, :fb_workplace_post_to_group_id, :string
    add_column :companies, :fb_workplace_enable_post_to_group, :boolean, default: false
  end
end
