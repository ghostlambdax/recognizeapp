# Run this with: 
#   [RAILS_ENV=production] bin/rails r db/users_export.rb --domain mindpointgroup.com

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
filename = "tmp/#{domain}-users.csv"
serializer_klass = UserSerializer

# A lesson in stubbing a view context...
# class SerializerContext
#   include ActionView::Helpers::UrlHelper
#   include ActionView::Helpers::FormOptionsHelper
#   include ActionView::Helpers::FormTagHelper
#   include ActionController::UrlFor
#   include Rails.application.routes.url_helpers
#   include UsersHelper

#   def initialize(company)
#     @company = company
#   end

#   def controller
#     Hashie::Mash.new(host: "")
#   end

#   def request
#     Hashie::Mash.new(host: "")
#   end

#   def env
#     Hashie::Mash.new
#   end

#   def current_user
#     nil
#   end

#   def l(*args)
#     I18n.l(*args)
#   end

#   def t(*args)
#     I18n.t(*args)
#   end
# end

except_attrs = [:full_name_link, :slug, :url]
opts = {except: except_attrs}
CSV.open(File.join(Rails.root, filename), 'wb') do |csv| 

  # headers, just use any user to serialize and get keys
  csv << serializer_klass.new(User.first, opts).as_json(root: false).keys

  c.users.each do |user|
    serializer = serializer_klass.new(user, opts)
    csv << serializer.as_json(root: false).values
  end
end

puts "Exported #{filename}"