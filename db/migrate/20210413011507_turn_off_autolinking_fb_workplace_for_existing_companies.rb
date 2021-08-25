class TurnOffAutolinkingFbWorkplaceForExistingCompanies < ActiveRecord::Migration[6.0]
  def up
    if Company.count > 1
      CompanySetting.update_all(autolink_fb_workplace_accounts: false)
    end
  end
end
