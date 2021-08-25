# frozen_string_literal: true

module ServerSideExportConcern
  extend ActiveSupport::Concern

  included do
    helper_method :datatable_export_url
  end

  # public controller action
  def queue_export
    # NOTE: rails 6 will change how timezone is done in ActiveJobs
    #       https://blog.saeloun.com/2019/03/02/rails-activejob-timezone-support.html
    DatatableExporterJob.perform_later datatable, Time.current, current_user.timezone_with_company_default
    head :ok
  end

  private

  def datatable_export_url
    # NOTE: You would think that Rails would retain the query parameters
    #       but I didn't see that, so have to manually merge it in
    url_for({action: :queue_export}.merge({exporter_action: params[:action]}).merge(request.query_parameters))
  end
end
