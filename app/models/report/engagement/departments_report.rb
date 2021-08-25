module Report
  module Engagement
    class DepartmentsReport < BaseAttributeReport
      
      def total_user_count_stat_for(department)
        total_user_count_by_departments_query.find { |record| record.department == department }.attributes
      end

      def point_activities_query
        @point_activities_query ||= begin
          select_query_chunks = ["IFNULL(users.department, 'UNASSIGNED') AS 'department'"]

          reportable_point_activity_types.each do |type|
            select_query_chunks << "SUM( CASE WHEN point_activities.activity_type='#{type}' THEN 1 ELSE 0 END ) AS #{type}"
          end

          select_query_chunks << "COUNT( DISTINCT(users.id) ) AS engaged_user_count"

          base_query
              .joins(:user)
              .where("users.status <> 'disabled'")
              .group("users.department")
              .select(select_query_chunks.join(","))
        end
      end

      def total_user_count_by_departments_query
        @total_user_count_by_departments_query ||= begin
          select_query_chunks = [
              "IFNULL(users.department, 'UNASSIGNED') AS 'department'",
              "COUNT( DISTINCT(users.id) ) AS user_count"
          ]

          ::User.where(company_id: company.id).not_disabled.group("users.department").select(select_query_chunks.join(","))
        end
      end

      def user_count_grouped_by_attribute_to_group_by
        total_user_count_by_departments_query.map { |record| Hashie::Mash.new(record.attributes) }
      end

      def attribute_to_group_by
        "department"
      end
    end
  end
end
