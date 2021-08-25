class Api::V2::Endpoints::System::JobCounts < Api::V2::Endpoints::System
  resource :system, desc: 'Interal use only' do
    # GET /jobs
    desc 'Get counts of jobs that are queued up' do
      detail 'Requires TRUSTED oauth scope'
    end

    oauth2 'trusted'
    route_setting(:x_auth_email, required: false)
    route_setting(:x_auth_network, required: false)

    get '/job_counts' do
      job_counts = Delayed::Job.where(failed_at: nil).group(:queue).count(:queue)
      present(:jobs, {type: "Message", ok: "success", jobs: job_counts})
      

    end

  end
end
