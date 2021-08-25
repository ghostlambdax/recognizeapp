# bin/rails r lib/import_tasks.rb --file=tmp/fsu-tasks.csv --domain=fsucu.org
require 'optparse'
opts = {}

parser = OptionParser.new do |options|
  options.on '-f', '--file FILE', 'CSV file with data to bulk recognize' do |arg|
    opts[:file] = arg
  end

  options.on '-f', '--domain DOMAIN', 'domain to import the tasks to' do |arg|
    opts[:domain] = arg
  end

end

parser.parse! ARGV
file = opts[:file]
suffix = Rails.env.production? ? "" : ".not.real.tld"
domain = opts[:domain] + suffix
puts "Opening file: #{file}"
csv = CSV.read(file, encoding: "ISO8859-1")

SCHEMA1 = {
  name: 0,
  # value: 1,
  points: 1,
  tag: 2,
  roles: 3
}

SCHEMA=SCHEMA1

errors = []

company = Company.where(domain: domain).first
csv.shift # remove headers
csv.each do |row|
  name = row[SCHEMA[:name]].strip
  # value = row[SCHEMA[:value]].strip.to_s.gsub('$','').to_f rescue nil
  points = row[SCHEMA[:points]].strip
  tag_name = row[SCHEMA[:tag]].strip
  role_names = (row[SCHEMA[:roles]]).split(",")

  company_roles = role_names.map do |role_name|
    CompanyRole.find_or_create_by(company_id: company.id, name: role_name)
  end
  t = Tskz::Task.find_or_initialize_by(company_id: company.id, name: name)
  t.points = points
  t.tag_name = tag_name
  t.company_roles = company_roles.map(&:id)
  unless t.save_with_options
    errors << [name, points, tag_name, role_names, e.message]
  end
end

errors.each do |err|
  puts err.to_s
end