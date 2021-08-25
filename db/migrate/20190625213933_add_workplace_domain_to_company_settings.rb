class AddWorkplaceDomainToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :workplace_com_share_domain, :boolean, default: false
  end
end
