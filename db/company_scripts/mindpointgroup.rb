suffix = Rails.env.production? ? "" : ".not.real.tld"
c = Company.where(domain: "mindpointgroup.com"+suffix).first
ar1 = Utility::AnniversaryResender.new(c, from: Time.parse("November 1, 2017"), to: Time.parse("December 31st, 2017"), opts: {send_birthday: false, send_anniversary: true})
ar2 = Utility::AnniversaryResender.new(c, from: Time.parse("January 1st, 2018"), to: Time.now, opts: {send_birthday: false, send_anniversary: true})