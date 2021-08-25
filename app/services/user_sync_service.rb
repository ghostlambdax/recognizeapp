# Wrapper for cron job
class UserSyncService
  def sync
    Company.program_enabled.sync_enabled.each do |company|
      if sync_is_within_sync_frequency?(company)
        UserSyncService.delay(queue: 'user_sync').sync_company(company.id)
        ManagerRoleSyncer.delay(queue: 'priority_caching').sync!(company.id)
      end
    end
  end

  def self.sync
    self.new.sync
  end

  def self.sync_company(company_id)
    tries = 0
    begin
      company = Company.find(company_id)
      provider = company.sync_provider
      
      company_admin = company.admin_sync_user(provider: provider)
      raise UserSync::NoSyncInitiator, [company.domain, provider] unless company_admin.present?
      Rails.logger.info "Running sync for company(#{provider}): #{company_id}-#{company_admin.id}"
      UserSyncJob.new(company: company, sync_initiator_id: company_admin.id).sync
      # UserSync::Yammer.sync(company: company, sync_initiator: company_admin)
    rescue UserSync::AuthenticationError => e
      # company_admin.authentications.send(provider).refresh! if provider.to_sym == :microsoft_graph
      ExceptionNotifier.notify_exception(e, data: { company: company, sync_initiator: company_admin.email, provider: provider })

      # try it with the next admin
      tries += 1
      if tries < company.company_admins.size + 1#should never hit up to tries + 1, but its a failsafe
        retry
      end

    rescue UserSync::NoSyncInitiator => e
      ::Recognizebot.say(text: "User sync failed for Company: #{company.domain} - Missing sync initiator for provider: #{provider}", channel: "#support-alerts")
      ExceptionNotifier.notify_exception(e, data: { company: company })

    rescue UserSync::Error => e
      ExceptionNotifier.notify_exception(e, data: { company: company })

    rescue => e
      ExceptionNotifier.notify_exception(e, data: { company: company })
    end
  end

  private
  def sync_is_within_sync_frequency?(company, date = Date.current)
    return false unless company.sync_enabled? || company.program_enabled?
    return true if company.last_synced_at.blank?
    return company.last_synced_at.to_date != date if company.settings.sync_frequency == 'daily'

    week_start = date.beginning_of_week
    week_end = date.end_of_week
    !(week_start..week_end).include?(company.last_synced_at.to_date)
  end
end
