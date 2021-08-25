# This report allows for filtering of recognitions by different attributes
# It uses a set of filter objects for each attribute and whether it applies to 
# a sender or receiver.
#
# Current support is:
#   - Sender Role
#   - Sender Country
#   - Sender Department
#   - Receiver Role
#   - Receiver Country
#   - Receiver Department
#
# The format for specifying the filters within the opts initialize parameter is:
#    {
#      filter: {
#        sender_role: {id: <sender_role_id>},
#        sender_country: {id: <sender_country_id>},
#        sender_department: {id: <sender_department_id>},
#        receiver_role: {id: <receiver_role_id>},
#        receiver_country: {id: <receiver_country_id>},
#        receiver_department: {id: <receiver_department_id>}
#      }
#    }
# Based on that, the appropriate fileters will be created and run when query is called.
#
class Report::RecognitionsFiltered < Report::Recognition
  include RecognitionReportFilter
  attr_reader :scope

  def initialize(company, scope=:company_role, from=50.years.ago, to=Time.now, opts={})
    super(company, from, to, opts)
    opts[:param_scope] = scope
    setup_filters
  end
end
