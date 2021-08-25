class RemoveOldFbWorkplaceSettingsFromCompany < ActiveRecord::Migration[4.2]
  def change
      settings = [
        :fb_workplace_community_id,
        :fb_workplace_post_to_group_id,
        :fb_workplace_enable_post_to_group,
        :fb_workplace_token   ]
      settings.each do |setting|
        remove_column :companies, setting
      end
  end
end
