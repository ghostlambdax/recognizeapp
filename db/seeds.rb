# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#

#its possible that we don't have the latest column information
#this occurs in the recognize:init rake task...probably because
#we access the User model in an early migration(loading the schema),
#and then remove a column, so we need to make sure we have latest table info
#before we do anything
ApplicationRecord.subclasses.each do |ar_klass|
  ar_klass.reset_column_information
end

#turn off observers - no need to send verification emails or whatever
ActiveRecord::Base.observers.disable :all

#Create badges if not already there
Badge::SET.each{|b| FactoryBot.create("#{b}_badge") unless Badge.exists?(name: b.to_s) }

#create system user
User.send(:_create_system_user!)

unless Rails.env.test?
  users = []
  begin
    retries ||= 0
    users << User.new(first_name: "Alex", last_name: "Grande", email: "alex@recognizeapp.com", password: "thisIsStrongPassword@!")
    users << User.new(first_name: "Peter", last_name: "Philips", email: "peter@recognizeapp.com", password: "thisIsStrongPassword@!")
    users << User.new(first_name: "Kate", last_name: "Cohen", email: "kate@recognizeapp.com", password: "thisIsStrongPassword@!")
    users << User.new(first_name: "Martin", last_name: "Karasek", email: "martin@recognizeapp.com", password: "thisIsStrongPassword@!")
    users << User.new(first_name: "Howard", last_name: "Wong", email: "howie@recognizeapp.com", password: "thisIsStrongPassword@!")
    users << User.new(first_name: "Pavel", last_name: "Ma&#269;ek", email: "pavel@recognizeapp.com", password: "thisIsStrongPassword@!")
    users << User.new(first_name: "Dev", last_name: "Hernandez", email: "dev@recognizeapp.com", password: "thisIsStrongPassword@!")
  rescue ActiveModel::UnknownAttributeError => e
    puts "Caught: #{e.class}: #{e}"
    Rails.logger.warn "Caught: #{e.class}: #{e}"
    retry if (retries += 1) < 3
  end
  users.each do |u|
    u.send(:ensure_company)
    u.send(:ensure_network)
    u.send(:ensure_slug)
    u.save
    u.verify_and_activate!
  end

  admins = User.where(email: ["alex@recognizeapp.com", "peter@recognizeapp.com"])
  admins.each do |a|
    a.roles << Role.admin unless a.admin?
    a.roles << Role.company_admin unless a.company_admin?
  end
end
FactoryBot.create(:company, name: "", domain: "users") unless Company.exists?(domain: "users")

#not sure if I need to turn this back on, as presumably this is the last file
#in the initalization rake task
ActiveRecord::Base.observers.enable :all
