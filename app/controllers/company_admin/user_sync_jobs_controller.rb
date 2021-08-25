module CompanyAdmin
  class UserSyncJobsController < CompanyAdmin::BaseController
    def create
      if @company.sync_enabled?
        UserSyncJob.new(company: @company, sync_initiator_id: current_user.id).delay(queue: 'user_sync').sync
      else
        head :ok
      end
    end
  end
end
