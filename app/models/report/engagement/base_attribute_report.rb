module Report
  module Engagement
    class BaseAttributeReport

      attr_reader :company, :from, :to, :opts, :data

      def self.results(company, from:, to:,opts: {})
        new(company, from: from, to: to, opts: opts)
      end

      def initialize(company, from:, to:,opts: {})
        date_range = DateRange.new(from, to)
        @company = company
        @from = date_range.start_time
        @to = date_range.end_time
        @opts = opts
      end

      def results
        @results ||= all_groups.map do |group|
          Hashie::Mash.new(point_activities_with_total_user_count_stat_for(group))
        end
      end

      def point_activities_with_total_user_count_stat_for(group)
        point_activity_stat_for(group).merge(total_user_count_stat_for(group))
      end

      def point_activity_stat_for(group)
        point_activity_record = point_activities_query.find do |record|
          record.send(attribute_to_group_by) == group
        end
        if point_activity_record.present?
          point_activity_record.attributes.except(:id)
        else
          null_point_activity_stat
        end
      end

      def base_query
        PointActivity
          .where(company_id: company.id)
          .where(created_at: from..to)
      end

      def query
        raise NotImplementedError, "Subclasses must define query method."
      end

      def group_by_attribute
        raise NotImplementedError, "Subclasses must define this method."
      end

      def user_count_grouped_by_attribute_to_group_by
        raise NotImplementedError, "Subclasses must define this method."
      end

      private

      # group may refer to teams/countries/department
      # Users for a group might not have matching point_activities. But, since these group's stats are reported
      # anyways, return (mock) point activity stat attributes by setting the relevant reportables to have `nil` value.
      def null_point_activity_stat
        Hash[reportable_attributes.zip([])]
      end

      def reportable_point_activity_types
        PointActivity.reportable_types
      end

      def reportable_attributes
        reportable_point_activity_types + %W[#{attribute_to_group_by} user_count engaged_user_count]
      end

      def all_groups
        user_count_grouped_by_attribute_to_group_by.map { |r| r.send(attribute_to_group_by) }
      end
    end
  end
end
