def migrate_domain(old_company_domain, new_company_domain)
  old_company_domain = old_company_domain + ".not.real.tld" if Rails.env.development?
  Company.where(domain: old_company_domain).first.update_column(:domain, new_company_domain)
  PointActivity.where(network: old_company_domain).update_all(network: new_company_domain)
  RecognitionRecipient.where(recipient_network: old_company_domain).update_all(recipient_network: new_company_domain)
  Team.where(network: old_company_domain).update_all(network: new_company_domain)
  User.where(network: old_company_domain).update_all(network: new_company_domain)
  CompanyDomain.where(domain: old_company_domain).update_all(domain: new_company_domain)
end