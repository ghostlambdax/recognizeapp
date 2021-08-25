module Report
  module Engagement
    class TeamsDatatable < BaseDatatable
      def first_column_attribute
        { title: "Team", orderable: true }
      end

      def all_records
        engagement_report.results
      end

      def filtered_records
        sort_column, sort_dir = sort_columns_and_directions.split(" ")
        data = all_records
        data = data.select { |x| x.team =~ /#{search_query}/i } if search_query.present?
        data = data.sort_by { |hsh| hsh.send(sort_column) }
        data = data.reverse if sort_dir == "desc"
        data.paginate(page: 1, per_page: per_page)
      end

      def columns
        columns = {
            0 => "team"
        }

        PointActivity.reportable_types.each_with_index do |type, index|
          columns[index+1] = type
        end

        columns[columns.size] = "user_count"
        columns
      end

      def namespace
        "engagement-reports-by-teams-datatable"
      end

      def serializer
        ReportByTeamsSerializer
      end

      def default_order
        "[[ 0, \"asc\" ]]"
      end

      def allow_search
        true
      end

      class ReportByTeamsSerializer < BaseDatatableSerializer
        REPORTABLES = %i[team user_count] + PointActivity.reportable_types.map(&:to_sym)
        def self.reportables
          REPORTABLES
        end

        attributes *reportables

        # The `object` here is a Hashie::Mash and not a type of ActiveModel. Therefore, this serializer doesn't come
        # with auto delegation of attributes to the object goodie of ActiveModel::Serializer.
        delegate *reportables, to: :object
      end
    end
  end
end

