# before
# users - 1862
# company admins - 7
# {"active"=>49,
# "disabled"=>6,
# "invited"=>4,
# "invited_from_recognition"=>11,
# "pending_invite"=>1782,
# "pending_signup_completion"=>10}
# c.users.group(:status).count(:status)

suffix = Rails.env.development? ? ".not.real.tld" : ""
c = Company.where(domain: 'bethanie.com.au'+suffix).first
company_admin_ids = c.company_admins.map(&:id)
total_users = c.users.size

# clear out all recognitions 
c.sent_recognitions.map{|r| r.destroy }
c.received_recognitions.each{|r| r.destroy if r.sender == User.system_user}

# disable all non company admin users
c.users.where.not(id: company_admin_ids).each{|u| u.disable! }

# import everyone and check status is pending invite
# do via web interface

# remove all disabled users
cleanup_users = c.users.disabled
cleanup_users.each{|u| u.destroy(deep_destroy: true) }
cleanup_users.each{|u| u.really_destroy! rescue nil }
cleanup_users.each{|u| User.with_deleted.delete(u.id) rescue nil  }

# make sure all users have direct report notifications turned off
c.users.each{|u| u.email_setting.update_column(:receive_direct_report_peer_recognition_notifications, false)}

# send everyone a text message
sms_msg = "Bethanie's L6 STARs system has been upgraded and is now powered by Recognize. Go to recognizeapp.com/bethanie.com.au/idp to send your first recognition. Keep Living The Six, Chris How"
errored_sms_user_ids = [] #[68589, 79594, 79841]

c.users.each_with_index do |u, index|
  if u.phone.present?
    Rails.logger.debug "BETHANIE: Sending SMS(#{index}/#{total_users}): #{u.email}(#{u.id})(#{u.phone})"
    begin
      Recognize::Application.twilio_client.send_sms(u.phone, sms_msg)
    rescue => e
      Rails.logger.debug "BETHANIE: Caught exception sending sms to #{u.email}(#{u.id})(#{u.phone}) - #{e.message}"
      errored_sms_user_ids << u.id
    end
  else
    Rails.logger.debug "BETHANIE: Skipping SMS(#{index}/#{total_users}): #{u.email}(#{u.id})(no phone)"
  end
end

# send everyone a recognition
c.reload
recognition_msg = "At Bethanie, I know our customers receive great care because of your hard work, determination and commitment. I want you to know that I value what you do each and everyday and that you truly make a difference. Thank you for making Bethanie a great place to work!  Thanks, Chris"
sender_email = "Christopher.How@bethanie.com.au"+suffix
sender = c.users.where(email: sender_email).first
badge = c.company_badges.where(id: 23199).first
recognition_opts = {is_private: true}
errored_recognition_user_ids = [] #[75731, 79391, 79491, 79553, 79994]

c.users.each_with_index do |u, index| 
  Rails.logger.debug "BETHANIE: Recognizing(#{index}/#{total_users}): #{u.email}(#{u.id})"
  begin
    sender.recognize!(u, badge, recognition_msg, recognition_opts)
  rescue => e
    Rails.logger.debug "BETHANIE: Caught exception sending recognition to #{u.email}(#{u.id}) - #{e.message}"
    errored_recognition_user_ids << u.id
  end
end
