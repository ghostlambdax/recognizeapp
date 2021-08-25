module ExternalActivities
  class SyncService

    def self.signature(method, args)
      company_id = args[0][:initiator].company_id
      "ExternalActivities##{method}(#{company_id})"
    end

    def self.sync_all_yammer_activities
      companies = Company.program_enabled.where(permit_yammer_stats: true, enable_yammer_stats: true)
      companies.each do |c|
        sync_user = c.admin_sync_user(provider: :yammer)
        sync_yammer_activities(initiator: sync_user)
      end
    end

    def self.sync_yammer_activities(initiator:, messages: [], stop_date: 1.month.ago)
      # make sure yammer ids are backfilled
      UidSyncer::CompanySyncer.sync(initiator.company)

      job_status = JobStatus.find_or_create_by(name: "sync_yammer_activities", company_id: initiator.company_id)

      job_status.record(initiator: initiator) do |job|
        if messages.empty?
          client = YammerClient.new(initiator.yammer_token, initiator)
          response = client.get_messages_through(stop_date: stop_date)
          messages = response.messages
          job.request_count = response.request_count
        end

        conversations = ExternalActivities::Yammer::Conversations.init_from_messages(messages)

        activities = []
        conversations.threads.each do |msgs|
          msgs.each do |msg|
            if msg.created_at >= stop_date
              msg.company_id = initiator.company.id
              external_activity = ExternalActivity.new_from_yammer_message(msg)
              activities << external_activity if external_activity.valid?
              msg.likes.each do |like|
                like.company_id = initiator.company.id
                activities << ExternalActivity.new_from_yammer_like(like)
              end
            end
          end
        end

        ExternalActivity.save_new_activities(activities)
        initiator.company.touch(:yammer_stats_synced_at)
      end
    end
  end
end
