class UserObserver < ActiveRecord::Observer
  def after_create(user)
    if user.invited?
      deliver_invitation_email!(user)

    elsif user.invited_from_recognition?
      #do nothing...we'll send a special email when the recognition is created
      
    #otherwise, send normal verification email
    elsif user.created_by == :oauth || user.created_by == :saml
      UserNotifier.delay(queue: 'priority').welcome_email(user)

    elsif !user.pending_invite?
      deliver_verification_email!(user) 
    end
    
    SafeDelayer.delay(queue: 'caching').run(Company, user.company_id, :refresh_cached_users!)
    # user.company.delay(queue: 'caching').refresh_cached_users!
  end

  def after_save(user)
    if Rails.env.production? && user.avatar.default? && user.auth_with_yammer?
      user.delay(queue: 'user_sync_low_priority').sync_yammer_avatar!
    end
  end

  def after_activate!(user)
    SafeDelayer.delay(queue: 'caching').run(Company, user.company_id, :refresh_cached_users!)
    # user.company.delay(queue: 'caching').refresh_cached_users!
    user.delay(queue: 'caching').refresh_cached_user_graph!
  end

  def after_destroy(user)
    SafeDelayer.delay(queue: 'caching').run(Company, user.company_id, :refresh_cached_users!)
    # user.company.delay(queue: 'caching').refresh_cached_users!
    # user.delay(queue: 'caching').refresh_cached_user_graph!
  end

  def deliver_invitation_email!(user)
    user.reset_perishable_token! if user.perishable_token.blank?
    UserNotifier.delay(queue: 'priority').invitation_email(user)
  end


  def deliver_verification_email!(user)
    user.reset_perishable_token! if user.perishable_token.blank?
    UserNotifier.delay(queue: 'priority').verification_email(user)
  end
end
