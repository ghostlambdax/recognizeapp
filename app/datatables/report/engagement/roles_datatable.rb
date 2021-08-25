module Report
  module Engagement
    class RolesDatatable < BaseDatatable
      def first_column_attribute
        { title: "Role", orderable: true }
      end

      def all_records
        system_role_results = begin
          company_admin_role_result = engagement_report[:system_roles][Role.company_admin.id]
          manager_role_result = engagement_report[:system_roles][Role.manager.id]
          [company_admin_role_result, manager_role_result]
        end
        company_role_results = engagement_report[:company_roles].values

        system_role_results + company_role_results
      end

      def filtered_records
        sort_column, sort_dir = sort_columns_and_directions.split(" ")
        sort_by_attribute = if sort_column == "name"
                              "long_name"
                            elsif sort_column == "user_count"
                              "user_count"
                            end
        results = all_records.sort_by do |record|
          record.send sort_by_attribute
        end
        results = results.reverse if sort_dir == "desc"
        results.paginate(page: page, per_page: per_page)
      end

      def columns
        columns = {
          0 => "name"
        }

        PointActivity.reportable_types.each_with_index do |type, index|
          columns[index+1] = type
        end

        columns[columns.size] = "user_count"

        return columns
      end

      def default_order
        "[[ 0, \"asc\" ]]"
      end

      def namespace
        "engagement-reports-by-role-datatable"
      end

      def serializer
        EngagementReportsByRoleSerializer
      end

      class EngagementReportsByRoleSerializer < BaseDatatableSerializer
        attributes(*(%i[name user_count] + PointActivity.reportable_types.map(&:to_sym)))

        def name
          object.long_name
        end
      end
    end
  end
end
