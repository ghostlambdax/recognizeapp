class UpdateAnniversaryNotifieds < ActiveRecord::Migration[4.2]
  def up
    Company.where(domain: "recognizeapp.com").each do |company|
      update_company(company)
    end
  end

  private
  def update_company(company)
    old_anniv_noties = company.anniversary_notifieds
    new_anniv_noties = old_anniv_noties.dup
    new_anniv_noties[:company_role_ids] = [companies_new_executive_role(company)]
    new_anniv_noties[:role_ids].delete(Role.executive.id)
    company.update_attribute(:anniversary_notifieds, new_anniv_noties)
  end

  def companies_new_executive_role(company)
    company.company_roles.detect{|cr| cr.name.match(/executive/i)}.try(:id)
  end
end
