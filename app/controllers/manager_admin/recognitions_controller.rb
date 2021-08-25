class ManagerAdmin::RecognitionsController < ManagerAdmin::BaseController

  include AdminRecognitionsConcern

  private
  def recognition_report(from, to)
    if filter_present?
      Report::RecognitionsByManagerFiltered.new(current_user,:company_role, from, to, params.merge(common_report_opts))
    else
      Report::RecognitionsByManager.new(current_user, from, to, params.merge(common_report_opts))
    end
  end
end
