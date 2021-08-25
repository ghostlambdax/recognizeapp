# bin/rails r lib/bulk.rb --domain=example.com --file=tmp/hms-201901.csv --private=true --skip-send-limits=true
require 'optparse'

opts = {}

parser = OptionParser.new do |options|
  options.on '-f', '--file FILE', 'CSV file with data to bulk recognize' do |arg|
    opts[:file_path] = arg
  end

  options.on '-d', '--domain DOMAIN', 'domain of the company that this relates to' do |arg|
    opts[:domain] = arg
  end

  options.on '-s', '--skip-notifications true|false', 'Skip all notifications that the recognition was sent' do |arg|
    opts[:skip_notifications] = (arg == 'true')
  end

  options.on '-l', '--skip-send-limits true|false', 'Skip send limit validations' do |arg|
    opts[:skip_send_limits] = (arg == 'true')
  end

  options.on '-p', '--private true|false', 'Sends the recognition privately, users still receive email notification of recognition' do |arg|
    opts[:is_private] = (arg == 'true')
  end

  options.on '-e', '--encoding ISO8859-1', 'Sets encoding of the CSV file' do |arg|
    opts[:encoding] = arg
  end

  options.on '-r', '--remote-file FILE', 'remote CSV file with data to bulk recognize' do |arg|
    opts[:remote_file_url] = arg
  end

  options.on '-i', '--input-format html|text', 'input format for the messages' do |arg|
    opts[:input_format] = arg
  end
end

parser.parse! ARGV
opts[:bulk_imported_at] = Time.current

opts[:input_format] = 'html' if opts[:input_format].blank?
raise OptionParser::MissingArgument.new("Must provide a valid csv file.") unless opts[:file_path].present? || opts[:remote_file_url].present?
raise OptionParser::MissingArgument.new("Domain argument cannot be blank.") if opts[:domain].blank?
raise OptionParser::InvalidArgument.new("Input format can either be html or text.") unless opts[:input_format].in? ['html', 'text']

company = Company.where(domain: opts[:domain]).first

raise "Company not found for domain: #{opts[:domain]}" if company.blank?

opts[:company_id] = company.id
email_suffix = Rails.env.production? ? "" : ".not.real.tld"

SCHEMA1 = {
  recipient_email_or_phone: 0,
  badge_id: 1,
  message: 2,
  sender_email: 3
}

SCHEMA2 = {
  sender_email: 0,
  recipient_email_or_phone: 1,
  badge_id: 2,
  message: 3
}

SCHEMA3 = {
  sender_email: 0,
  recipient_email_or_phone: 1,
  badge: 2,
  message: 3
}

SCHEMA = SCHEMA3
SCHEMA[:point_value] = SCHEMA.values.max + 1 # last column

options = opts.slice(:file_path, :company_id, :skip_notifications, :is_private, :skip_send_limits, :encoding, :bulk_imported_at, :remote_file_url, :input_format)

BulkRecognition::Importer.run(SCHEMA, email_suffix, options)
