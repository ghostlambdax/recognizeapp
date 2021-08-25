module Report
  module Engagement
    class ResultBase
      extend ActiveModel::Naming
      include ActiveModel::Serialization
      attr_reader :report_by, :results

      def initialize(report_by, results = {})
        @report_by = report_by
        @results = results
      end

      PointActivity.reportable_types.each do |activity_type|
        define_method(activity_type) do
          @results[activity_type]
        end
      end

      PointActivity.reportable_types.each do |activity_type|
        define_method("#{activity_type}=") do |count|
          @results[activity_type] = count
        end
      end

      def attributes
        PointActivity.reportable_types.inject({}) do |hash, activity_type|
          hash[activity_type] = @results[activity_type]
          hash
        end
      end
    end
  end
end
