require 'rubygems'
require 'sitemap_generator'

# Put links creation logic here.
#
# The root path '/' and sitemap index file are added automatically for you.
# Links are added to the Sitemap in the order they are specified.
#
# Usage: add(path, options={})
#        (default options are used if you don't specify)
#
# Defaults: :priority => 0.5, :changefreq => 'weekly',
#           :lastmod => Time.now, :host => default_host
#
# Examples:
#
# Add '/articles'
#
#   add articles_path, :priority => 0.7, :changefreq => 'daily'
#
# Add all articles:
#
#   Article.find_each do |article|
#     add article_path(article), :lastmod => article.updated_at
#   end

SitemapGenerator::Sitemap.default_host = 'https://recognizeapp.com'
SitemapGenerator::Sitemap.compress = true
SitemapGenerator::Sitemap.create do
  add_to_index "/sitemap.xml.gz"
  add '/', changefreq: 'weekly', priority: 0.9

  %w(pricing tour rewards employee-nominations employee-anniversaries incentives
  employee-recognition-awards office-365 outlook yammer-integration
  slack-employee-recognition employee-recognition-facebook-workplace
  mobile-employee-recognition analytics customizations engagement features
  gamification employee-recognition-report engagement-report
  case-study resources top-employee-recognition-ideas employee-reward-ideas
  employee-engagement-glossary icons distributed-workforce-infographic
  why-employee-recognition recognize-security-overview.pdf sign-up
  sales help terms contact privacy recognize-privacy-shield-policy.pdf
  docs/getting-started/recognize-implementation-guide.pdf
  docs/getting-started/launch-checklist.pdf
  docs/about/fb-workplace.pdf get-started-employees.pdf
  docs/getting-started/outlook-user-guide.pdf get-started-employees-yammer.pdf
  docs/getting-started/recognize-getting-started-chrome-office365.pdf
  docs/getting-started/recognize-getting-started-txt.pdf best-practices-handbook.pdf
  docs/getting-started/recognize-user-sync-guide.pdf
  docs/getting-started/import-spreadsheet-instructions.pdf
  docs/product/product-getting-started-checklist.pdf docs/product/nominations.pdf
  docs/product/achievement-strategy.pdf docs/product/points-rewards-setup.pdf
  docs/getting-started/recognize-strategy.pdf company-engagement-strategy.pdf
  docs/integrations/recognize-technology-overview.pdf recognize-security-overview.pdf
  recognize-security-saml.pdf docs/integrations/third_party_integrations.pdf
  docs/integrations/recognize-o365-sharepoint-implementation-guide.pdf
  docs/integrations/RecognizeOnPremSharepointImplementationGuide.pdf
  recognize-chrome-grouppolicy-v2.adm docs/integrations/integrations-overview.pdf
  recognize_ie_extension_user_guide.pdf
  docs/integrations/recognize-outlook-implementation-guide.pdf
  docs/integrations/yammer-overview.pdf).each do |page|
    add page, changefreq: "weekly"
  end
end
# SitemapGenerator::Sitemap.ping_search_engines # Not needed if you use the rake tasks
