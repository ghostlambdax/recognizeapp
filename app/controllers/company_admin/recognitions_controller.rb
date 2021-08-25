class CompanyAdmin::RecognitionsController < CompanyAdmin::BaseController
  include AdminRecognitionsConcern

  private

  def recognition_report(from, to)
    if filter_present?
      # for now only allow role filtering by company roles, but this report supports system roles too
      # just need to implement how to differentiate company/system roles via the ui
      Report::RecognitionsFiltered.new(@company, :company_role, from, to, params.merge(common_report_opts))
    else
      Report::Recognition.new(@company, from, to, params.merge(common_report_opts))
    end
  end
end
