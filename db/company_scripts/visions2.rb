# data = [{"JRosenbe@visionsfcu.org" => "JRosenberg@visionsfcu.org"},
# {"SKermida@visionsfcu.org" => "SKermidas@visionsfcu.org"},
# {"sburghar@visionsfcu.org" => "sburghar@visionsfcu.org"},
# {"hdrzazgo@visionsfcu.org" => "hdrzazgowski@visionsfcu.org"},
# {"mevans@visionsfcu.org" => "MEvans1@visionsfcu.org"},
# {"amontgom@visionsfcu.org" => "amontgomery@visionsfcu.org"},
# {"csisco@visonsfcu.org" => "CSisco@visionsfcu.org"},
# {"bvanalst@visionsfcu.org" => "bvanalstine@visionsfcu.org"},
# {"DMcaiste@visionsfcu.org" => "DMcaister@visionsfcu.org"},
# {"LPetrill@visionsfcu.org" => "LPetrilli@visionsfcu.org"},
# {"KMcDanie@visionsfcu.org" => "KMcDaniels@visionsfcu.org"},
# {"BKropeln@visionsfcu.org" => "BKropelnicki@visionsfcu.org"},
# {"KDiffend@visionsfcu.org" => "kdiffendorf@visionsfcu.org"},
# {"JFairchi@visionsfcu.org" => "JFairchild@visionsfcu.org"},
# {"PPietros@visionsfcu.org" => "PPietros@visionsfcu.org"},
# {"JKleespi@visionsfcu.org" => "JKleespies@visionsfcu.org"},
# {"SSanguin@visionsfcu.org" => "SSanguin@visionsfcu.org"},
# {"SDelahan@visionsfcu.org" => "SDelahanty@visionsfcu.org"},
# {"CSheffie@visionsfcu.org" => "CSheffie@visionsfcu.org"},
# {"CMalewic@visionsfcu.org" => "CMalewicz@visionsfcu.org"},
# {"KLeStrang@visionsfcu.org" => "KLeStrange@visionsfcu.org"},
# {"DFerguso@visionsfcu.org" => "dferguson@visionsfcu.org"},
# {"JChristo@visionsfcu.org" => "jchristopher@ecdschool.org"},
# {"lbalestr@visionsfcu.org" => "LBalestri@visionsfcu.org"},
# {"sullivan@visionsfcu.org" => "BSullivan@visionsfcu.org"},
# {"EBlaisur@visionsfcu.org" => "EBlaisure@visionsfcu.org"},
# {"SAtanasi@visionsfcu.org" => "SAtanasio@visionsfcu.org"},
# {"DSanyshy@visionsfcu.org" => "DSanyshyn@visionsfcu.org"},
# {"JCirigli@visionsfcu.org" => "JCirigliano@visionsfcu.org"},
# {"CAlfaran@visionsfcu.org" => "CAlfaran@visionsfcu.org"},
# {"TODonnel@visionsfcu.org" => "TODonnel@visionsfcu.org"},
# {"ASpauldi@visionsfcu.org" => "aspaulding@visionsfcu.org"},
# {"MMccarth@visionsfcu.org" => "MMcCarthy@visionsfcu.org"},
# {"DMcMicke@visionsfcu.org" => "DMcMicken@visionsfcu.org"},
# {"SSulliva@visionsfcu.org" => "SSulliva@visionsfcu.org"}]

data = [{"satanasi@visionsfcu.org" => "satanasio@visionsfcu.org"},
{"lgoryelo@visionsfcu.org" => "lgoryelova@visionsfcu.org"},
{"Mhughsto@visionsfcu.org" => "mhughston@visionsfcu.org"},
{"EPecorar@visionsfcu.org" => "epecoraro@visionsfcu.org"},
{"christa.perry@lpl.com" => "CPerry@visionsfcu.org"},
{"esorber@visionsfcu.org" => "eriley@visionsfcu.org"},
{"CSchaffe@visionsfcu.org" => "CSchaffer@visionsfcu.org"},
{"RSeabroo@visionsfcu.org" => "RSeabrook@visionsfcu.org"},
{"ekasten@visionsfcu.org" => "esmith@visionsfcu.org"},
{"sullivan@visionsfcu.org" => "bsullivan@visionsfcu.org"}]

require File.join(Rails.root, 'db/merge_users')
suffix = Rails.env.development? ? ".not.real.tld" : ""
data.each do |pair|
 begin
   bad_email, good_email = pair.keys.first+suffix, pair.values.first+suffix
   bad_user = User.where(email: bad_email).first
   good_user = User.where(email: good_email).first
   move_user_records(bad_user, good_user)
   bad_user.reload
   bad_user.destroy
   bad_user.really_destroy!
 rescue => e
   Rails.logger.info "Could not process(#{e.message}): #{bad_email}(#{bad_user.try(:id)})|#{good_email}(#{good_user.try(:id)})"
 end
end