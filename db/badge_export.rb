# Run this with: 
#   [RAILS_ENV=production] bin/rails r db/badge_export.rb --domain mindpointgroup.com

require 'optparse'
opts = {}

parser = OptionParser.new do |options|
  options.on '-f', '--domain DOMAIN', 'Domain to export the badges for' do |arg|
    opts[:domain] = arg
  end
end

parser.parse! ARGV
domain = opts[:domain]

suffix = Rails.env.development? ? ".not.real.tld" : ""
c = Company.where(domain: domain+suffix).first
filename = "tmp/#{domain}-badges.csv"
CSV.open(File.join(Rails.root, filename), 'wb') do |csv| 

  # headers, just use any badge to serializer and get keys
  csv << BadgeSerializer.new(Badge.first).as_json(root: false).keys

  c.company_badges.each do |badge|
    serializer = BadgeSerializer.new(badge)
    csv << serializer.as_json(root: false).values
  end
end

puts "Exported #{filename}"