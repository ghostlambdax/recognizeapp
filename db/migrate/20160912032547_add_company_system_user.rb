class AddCompanySystemUser < ActiveRecord::Migration[4.2]
  def up
    # Data migration has been pushed to production. This migration is now irrelevent.
    # b = Badge.where(company_id: nil, short_name: "Ambassador").first
    # b.update_column(:points, 0) unless Rails.env.test?
  end

  def down
  end
end
