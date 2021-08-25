module IntervalNotificationRunner
  module Reports
    class ForecastReport
      attr_reader :results
      delegate :each, to: :results

      def initialize
        @results = []
      end

      # errors common across all runs
      def super_global_errors
        # we cannot deduce if it's a super-global error if there is only a single run result in the report
        return [] if results.count == 1

        # finds the intersecting elements among the global errors in individual reports
        @super_global_errors ||= results.map do |_ref_time, run_report|
          run_report.global_errors(true) || []
        end.inject(:&)
      end

      # aggregates #global_errors for all runs
      # Note: RunReport#global_errors (that is invoked here) ignores reports having only single company
      #       but that is still shown/accounted for in the report email if that error is included in super_global_errors
      def global_errors(include_super_global_errors = true)
        errors = results.map do |_ref_time, run_report|
          run_report.global_errors
        end.flatten.uniq

        errors -= super_global_errors unless include_super_global_errors
        errors
      end

      def push(reference_time, run_report)
        results.push([reference_time, run_report])
      end

      def total_email_count
        @total_email_count ||= results.sum{|_ref_time, run_report| run_report.total_email_count }
      end

      def total_error_count
        @total_error_count ||= results.sum{|_ref_time, run_report| run_report.total_error_count }
      end

      def unique_error_count
        @unique_error_count ||= begin
          results.map{|_ref_time, run_report| run_report.unique_errors}.flatten.uniq.count
        end
      end

      def unique_company_with_results_count
        @unique_company_with_results_count ||= begin
          results.map{|_ref_time, run_report| run_report.results.map(&:company) }.flatten.uniq.count
        end
      end

      def unique_company_with_empty_results_count
        @unique_company_with_empty_results_count ||= begin
          results.map{|_ref_time, run_report| run_report.companies_with_empty_results }.flatten.uniq.count
        end
      end

      def unique_company_count
        @unique_company_count ||= unique_company_with_results_count + unique_company_with_empty_results_count
      end

      def erroneous_company_count
        @erroneous_company_count ||= results.map do |_ref_time, run_report|
          run_report.erroneous_companies
        end.flatten.uniq.count
      end
    end
  end
end
