def move_user_records(old_user, active_user)
  # active_user.yammer_id = old_user.yammer_id if active_user.yammer_id.blank?
  # active_user.microsoft_graph_id = old_user.microsoft_graph_id if active_user.microsoft_graph_id.blank?
  # active_user.synced_at = old_user.synced_at if active_user.synced_at.blank?
  # active_user.crypted_password = old_user.crypted_password if active_user.crypted_password.blank?
  # active_user.password_salt = old_user.password_salt if active_user.password_salt.blank?
  # active_user.persistence_token = old_user.persistence_token if active_user.persistence_token.blank?
  # active_user.invited_by_id = old_user.invited_by_id if active_user.invited_by_id.blank?
  # active_user.invited_at = old_user.invited_at if active_user.invited_at.blank?
  # active_user.status = old_user.status if old_user.active?
  # active_user.start_date = old_user.start_date if active_user.start_date.blank?
  # active_user.birthday = old_user.birthday if active_user.birthday.blank?
  # active_user.phone = old_user.phone if active_user.phone.blank?
  # active_user.manager_id = old_user.manager_id if active_user.manager_id.blank?
  # active_user.save(validate: false)
  
  Authentication.where(user_id: old_user.id).update_all(user_id: active_user.id) if active_user.authentications.blank?
  Recognition.where(sender_id: old_user.id).update_all(sender_id: active_user.id, sender_company_id: active_user.company_id)
  RecognitionApproval.where(giver_id: old_user.id).update_all(giver_id: active_user.id)
  PointActivity.where(user_id: old_user.id).update_all(user_id: active_user.id, company_id: active_user.company_id)
  RecognitionRecipient.where(user_id: old_user.id).update_all(user_id: active_user.id, recipient_company_id: active_user.company_id)

  Comment.where(commenter_id: old_user.id).update_all(commenter_id: active_user.id)
  DeviceToken.where(user_id: old_user.id).update_all(user_id: active_user.id)
  #EmailLog.where(user_id: old_user.id).update_all(user_id: active_user.id)
  EmailSetting.where(user_id: old_user.id).update_all(user_id: active_user.id)
  Nomination.where(recipient_id: old_user.id).update_all(recipient_id: active_user.id, recipient_company_id: active_user.company_id)
  NominationVote.where(sender_id: old_user.id).update_all(sender_id: active_user.id, sender_company_id: active_user.company_id)
  Redemption.where(user_id: old_user.id).update_all(user_id: active_user.id, company_id: active_user.company_id)
  Tskz::TaskSubmission.where(submitter_id: old_user.id).update_all(submitter_id: active_user.id)
  #Reward.where(manager_id: old_user.id).update_all(manager_id: active_user.id)
end

def log(msg)
  puts msg
  Rails.logger.info msg
end

def dup_accounts?(company_id: )
  if company_id.present?
    set = User.where(company_id: company_id).group(:email).having("count_email > 1").count(:email)
  else
    set = User.group(:email).having("count_email > 1").count(:email)
  end

  # set.keys.map{|e| User.where(email: e).map(&:network)}
  set2 = set.select do |email, count|
    users = User.where(email: email)
    users = users.group_by(&:network).reject{|e,d| d.length == 1}
    users.present?
  end
  set2.length > 0
end

def cleanup(company_id: )
  if company_id.present?
    set = User.where(company_id: company_id).group(:email).having("count_email > 1").count(:email)
  else
    set = User.group(:email).having("count_email > 1").count(:email)
  end

  # set.keys.map{|e| User.where(email: e).map(&:network)}
  set2 = set.select do |email, count|
    log "set2 << #{email}"
    users = User.where(email: email)
    users = users.group_by(&:network).reject{|e,d| d.length == 1}
    users.present?
  end

  log "Moving #{set2.length}"
  set2.each do |email, count|
    users = User.where(email: email)
    users = users.group_by(&:network).reject{|e,d| d.length == 1}
    users.each do |network, u|
      if u[0].active?
        active_user = u[0]
        old_user = u[1]
      else
        active_user = u[1]
        old_user = u[0]
      end

      log "moving #{network} - #{old_user.id}(#{old_user.email}) - #{active_user.id}(#{active_user.email})"
      move_user_records(old_user, active_user)
      old_user.destroy(deep_destroy: true)
      active_user.update_all_points!
    end
  end
end

# while(dup_accounts?)
#   log "Found duplicate accounts - Cleaning up...."
#   cleanup
# end

# User.update_all("unique_key = CONCAT(email,'-',network)")
