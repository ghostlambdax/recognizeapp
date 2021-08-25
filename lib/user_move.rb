active_user = User.find(45970)
old_user = User.find(45973)
changing_company = old_user.company_id != active_user.company_id
update_authentication = true

raise "Really?" if changing_company

def log(subject, count)
  puts "Updating #{subject}: #{count}"
end

if update_authentication
  active_user.crypted_password = old_user.crypted_password
  active_user.password_salt = old_user.password_salt
  active_user.status = "active" # force active
  active_user.save
  log Authentication, Authentication.where(user_id: old_user.id).update_all(user_id: active_user.id)
end

log Recognition, Recognition.where(sender_id: old_user.id).update_all(sender_id: active_user.id, sender_company_id: active_user.company_id)
log RecognitionApproval, RecognitionApproval.where(giver_id: old_user.id).update_all(giver_id: active_user.id)
log PointActivity, PointActivity.where(user_id: old_user.id).update_all(user_id: active_user.id, company_id: active_user.company_id)
log RecognitionRecipient, RecognitionRecipient.where(recipient_type: "User", recipient_id: old_user.id).update_all(recipient_id: active_user.id, recipient_company_id: active_user.company_id)

log Comment, Comment.where(commenter_id: old_user.id).update_all(commenter_id: active_user.id)
log DeviceToken, DeviceToken.where(user_id: old_user.id).update_all(user_id: active_user.id)
log EmailSetting, EmailSetting.where(user_id: old_user.id).update_all(user_id: active_user.id)
log Nomination, Nomination.where(recipient_type: "User", recipient_id: old_user.id).update_all(recipient_id: active_user.id, recipient_company_id: active_user.company_id)
log NominationVote, NominationVote.where(sender_id: old_user.id).update_all(sender_id: active_user.id, sender_company_id: active_user.company_id)
log Redemption, Redemption.where(user_id: old_user.id).update_all(user_id: active_user.id, company_id: active_user.company_id)

unless changing_company
  log Reward, Reward.where(manager_id: old_user.id).update_all(manager_id: active_user.id)
  log Subscription, Subscription.where(user_id: old_user.id).update_all(user_id: active_user.id)
  log TeamManager, TeamManager.where(manager_id: old_user.id).update_all(manager_id: active_user.id)
  log UserCompanyRole, UserCompanyRole.where(user_id: old_user.id).update_all(user_id: active_user.id, company_role_id: active_user.company_id)
  log UserPermission, UserPermission.where(user_id: old_user.id).update_all(user_id: active_user.id)
  log UserRole, UserRole.where(user_id: old_user.id).update_all(user_id: active_user.id)
  log UserTeam, UserTeam.where(user_id: old_user.id).update_all(user_id: active_user.id)
end

log "old user point totals", old_user.reload.update_all_points!
log "active user point totals", active_user.reload.update_all_points!