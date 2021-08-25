#!/usr/bin/env ruby
# This is a helper for the 'bulk recognition' process, the script makes no
#  data changes; it simply gathers info (via asking questions) needed to run
#  the bulk recognition process and produces documentation used in the process.
#
# To Run: $ ruby bulk_recognize_helper.rb


def get_user_input(prompt, default)
    print(prompt)
    r = gets.chomp
    if r.length() > 0
        return r
    else
        return default
    end
end

puts %Q(
################################
# Bulk Recognition Helper      #
################################

This script gathers all info needed to run a bulk recognition and provides the command to run a BR.

)

domain = get_user_input("What is the domain? ", "")
filename = get_user_input("What is the filename? ", "")

puts "
- retrieving file url from filename (usually takes ~30s)"
puts "---------------------------------"
r = IO.popen("RAILS_ENV=production bundle exec rails console", "r+")
r.write "Rails.logger.level = :error
"
r.write "p Company.where(domain: '#{domain}').first.documents.where(original_filename: '#{filename}').last.url
"
r.write "exit
"
results = []
r.each do |line|
  results.append(line)
end
puts "---------------------------------"
fileurl = results[results.length() - 2].tr('"', '').chomp
if fileurl.length() < 1 || fileurl.start_with?("NoMethodError")
    abort("ERROR: File: '#{filename}' was not found for domain: '#{domain}', Cannot continue.")
end
puts "- file url found
"
skip_send_limits = get_user_input("- skip send limits? (*true/false) ", "true")
skip_notifications = get_user_input("- skip notifications? (true/*false) ", "false")
private = get_user_input("- private? (*true/false) ", "true")

puts %Q(
----------- RUN SUMMARY -----------
- skip send limits: #{skip_send_limits}
- skip notifications: #{skip_notifications}
- private: #{private}
- domain: #{domain}
- file url: #{fileurl}

----------- RUN COMMAND -----------
RAILS_ENV=production bundle \\
  exec rails r lib/bulk.rb \\
  --skip-send-limits=#{skip_send_limits} \\
  --skip-notifications=#{skip_notifications} \\
  --private=#{private} \\
  --domain='#{domain}' \\
  --remote-file #{fileurl}
)
