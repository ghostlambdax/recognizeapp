class Report::RecognitionsByManagerFiltered < Report::RecognitionsByManager
  include RecognitionReportFilter
  attr_reader :manager, :scope

  def initialize(manager, scope=:company_role, from=50.years.ago, to=Time.now, opts={})
    @manager = manager
    @company = manager.company
    super(@manager, from, to, opts)
    opts[:param_scope] = scope
    setup_filters
  end
end

