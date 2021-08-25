class MoveFbWorkplaceSettingsOverToCompanySettings < ActiveRecord::Migration[4.2]
  def up
    # data migration only, dont run on init
    if Company.count > 0
      settings = [
        :fb_workplace_community_id,
        :fb_workplace_post_to_group_id,
        :fb_workplace_enable_post_to_group,
        :fb_workplace_token   ]

      Company.where.not(:fb_workplace_community_id => nil).each do |c|
        settings.each do |setting|
          c.settings.send("#{setting}=", c.send(setting))
          c.settings.save!
        end
      end
    end
  end
end