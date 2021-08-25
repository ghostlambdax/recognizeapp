bin/rails r lib/company_import.rb --file=tmp/sonae.csv --schema=1 --domain=sonae.pt --sender-email=ahgoncalves@sonaemc.com --date-format=%d/%m/%Y --invite=false
require File.join(Rails.root, 'db/merge_users')
suffix = Rails.env.development? ? '.not.real.tld' : ''
c = Company.where(domain: "sonae.pt#{suffix}").first

c.users.each{|u| 
  possible_dupes = User.where(email: u.email)
  if possible_dupes.length > 1
    dupes = possible_dupes.reject{|pd| pd.network == c.domain}
    dupes.each do |dupe|
      move_user_records(dupe, u)
      dupe.destroy(deep_destroy: true)
    end
  end
}

c.reload
c.users.select{|u| User.where(email: u.email).size > 1}.length