module IntervalNotificationRunner
  module Reports
    class RunReport
      attr_reader :results, :companies_with_empty_results

      CompanyReport = Struct.new(:company, :emails, :errors)

      def initialize
        @results = []
        @companies_with_empty_results = []
      end

      def push(company, report)
        # store companies with empty results in a separate array
        if report.emails.present? || report.errors.present?
          results << CompanyReport.new(company, report.emails, report.errors)
        else
          companies_with_empty_results << company
        end
      end

      def results_excluding_global_errors(errors_to_exclude = global_errors)
        return results if errors_to_exclude.empty?

        results.map do |company_result|
          company_result.dup.tap do |r|
            r.errors = r.errors.reject{ |e| e.in?(errors_to_exclude) }
          end
        end
      end

      def total_email_count
        @total_email_count ||= results.sum do |company_report|
          company_report.emails.count
        end
      end

      def erroneous_companies
        @erroneous_companies ||= results
                                   .select { |company_report| company_report.errors.present? }
                                   .map(&:company).uniq
      end

      def erroneous_company_count
        erroneous_companies.count
      end

      def total_error_count
        @total_error_count ||= results.sum do |company_report|
          next(0) unless company_report.errors.present?

          company_report.errors.sum do |_e, recipient_emails|
            # recipient_emails can be empty if the error occurred at company-level
            recipient_emails.present? ? recipient_emails.count : 1
          end
        end
      end

      def unique_errors
        @unique_errors ||= begin
          errors = results.map(&:errors).map(&:keys).flatten
          # using inspect() for appropriate string conversion of Exception instances to compare them correctly
          errors.group_by(&:inspect).values.map(&:first)
        end
      end

      def unique_error_count
        unique_errors.count
      end

      def global_errors(include_reports_with_single_company = false)
        # unless there are multiple companies, we cannot deduce if its a global error
        # but this is still useful for detecting super-global errors in forecast (with arg override)
        if results.count <= 1 && !include_reports_with_single_company
          return []
        end

        # finds the intersection between report error for all companies
        # if the same error is present for all companies in the report, we call it global error
        @global_errors ||= results.map { |company_report| company_report.errors.keys }.inject(:&)
      end

      def company_count
        results.count + companies_with_empty_results.count
      end
    end
  end
end