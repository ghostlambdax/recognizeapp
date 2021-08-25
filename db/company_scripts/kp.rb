c = Company.where(domain: "kp.org").first
# c.family.map{|co| co.users.reject{|u| u.active? || u.disabled?}.map{|u| [u.id, u.network, u.status, u.email, u.manager.try(:email), u.perishable_token]}}[1]
data = c.family.map{|co| co.users.reject{|u| u.active? || u.disabled?}.map{|u| [u.id, u.network, u.status, u.email, u.manager.try(:email), "https://recognizeapp.com/signup/#{u.perishable_token}/verify"]}}
# d2 = data[0] + data[1] + data[2] + data[3]
d2 = data.inject([]){|arr, d| arr += d; arr }
CSV.open(File.join(Rails.root, "tmp/kp5.csv"), 'wb') {|csv| d2.each{|d| csv << d}}