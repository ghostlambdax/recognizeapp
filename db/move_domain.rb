# NOTICES:
#   - this script likely wont work if the domain has a custom theme - you will likely need a deploy!
#   - rsync/copy (NOT MOVE) the theme data first
#   - after this script is complete check the new domain to ensure css, logos, etc are showing/working correctly
#   - if everything is working as expected you can delete the old theme data
#   - DO NOT FORGET to make the corresponding changes in source or the theme data will be reset on the next deploy!
#
#  Theme Data: you need the 'source' theme data which consists of two parts:
#    - stylesheet(s): app/assets/stylesheets/themes/{domain}.scss
#    - image(s): app/assets/images/themes/{domain}/
#
# Execute With: `RAILS_ENV=production bundle exec rails r db/move-domain.rb`


suffix = Rails.env.development? ? ".not.real.tld" : ""
old_domain = "remedy-one.com" + suffix
new_domain = "goodrootinc.com" + suffix

# turn off theme before moving stuff
Company.where(domain: old_domain).first.update_column(:has_theme, false)

Company.where(domain: old_domain).update_all(domain: new_domain, slug: new_domain)
CompanyDomain.where(domain: old_domain).update_all(domain: new_domain)
User.where(network: old_domain).update_all(network: new_domain)
PointActivity.where(network: old_domain).update_all(network: new_domain)
RecognitionRecipient.where(recipient_network: old_domain).update_all(recipient_network: new_domain)
Team.where(network: old_domain).update_all(network: new_domain)

# recompile rails assets to pick up theme change
Company.where(domain: new_domain).first.custom_theme.compile!

# turn theme back on
Company.where(domain: new_domain).first.update_column(:has_theme, true)

# NOTICE: you may need/want to add the old domain to the new domains list of domains like
#c = Company.where(domain: new_domain).first
#c.domains << CompanyDomain.new(domain: old_domain)
