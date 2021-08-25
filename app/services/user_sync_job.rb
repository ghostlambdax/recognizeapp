# Main wrapper for creating sync jobs
# Will be called directly by controller in on-demand use case
# Nightly bg job calls it from UserSyncService
class UserSyncJob
  attr_reader :company, :sync_initiator

  def initialize(company: , sync_initiator_id: company.admin_sync_user(provider: company.sync_provider))
    @company = company
    @sync_initiator_id = sync_initiator_id #user 
  end

  def method_name
    "sync"
  end

  def sync_initiator
    @sync_initiator ||= User.find(@sync_initiator_id) if @sync_initiator_id
  end

  def syncer
    if company.sync_provider.to_sym == :yammer
      ::UserSync::Yammer.new(company: company, sync_initiator: sync_initiator)
    else
      ::UserSync::MicrosoftGraph.new(company: company, sync_initiator: sync_initiator)
    end
  end

  def sync
    if sync_initiator.present?
      syncer.sync
    else
      Rails.logger.debug "No sync initiator for #{@company.id}-#{@company.domain}, skipping..."
    end
  end

  def queue_name
    "user_sync"
  end

  def signature
    "UserSyncJob:#{@company.id}"
  end
end
