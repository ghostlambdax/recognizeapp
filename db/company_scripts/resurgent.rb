suffix = Rails.env.development? ? '.not.real.tld' : ''
c = Company.where(domain: "resurgent.com#{suffix}").first
c.recognitions.map{|r| r.destroy! }
c.users.reject{|u| u.company_admin? }.map{|u| u.destroy(deep_destroy: true)}