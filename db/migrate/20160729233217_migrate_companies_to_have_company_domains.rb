class MigrateCompaniesToHaveCompanyDomains < ActiveRecord::Migration[4.2]
  def up
    Company.all.each do |c|
      CompanyDomain.create(company: c, domain: c.domain)
    end
  end
end
