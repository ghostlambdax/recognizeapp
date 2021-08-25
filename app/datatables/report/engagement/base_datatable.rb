require "will_paginate/array"
module Report
  module Engagement
    class BaseDatatable < ::DatatablesBase
      attr_reader :engagement_report

      FIRST_COLUMN_WIDTH_PERCENTAGE = 25

      # The ordering of the columns in the table will
      # be in the following order: `first_column_attribute` column, `PointActivity.reportable_types` columns and
      # `additional_column_attributes` columns.
      def column_attributes
        @column_attributes ||= begin
          col_attrs = {}
          col_attrs[0] = { orderable: first_column_attribute[:orderable], title: first_column_attribute[:title], width: "#{FIRST_COLUMN_WIDTH_PERCENTAGE}%" }
          PointActivity.reportable_types.each do |activity_type|
            col_attrs[col_attrs.length] = { orderable: false,
                                            width: "#{non_first_columns_width_percentage}%",
                                            title: I18n.t("point_activities.count_labels.#{activity_type}"),
                                            defaultContent: 0 }
          end
          additional_column_attributes.each do |column_attribute|
            col_attrs[col_attrs.length] = { orderable: column_attribute[:orderable] || false,
                                            title: column_attribute.fetch(:title),
                                            width: "#{non_first_columns_width_percentage}%",
                                            defaultContent: 0 }
          end
          col_attrs
        end
      end

      def first_column_attribute
        raise "Must be implemented by subclass"
      end

      def non_first_columns_width_percentage
        @non_first_columns_width_percentage ||= begin
          (100.0 - FIRST_COLUMN_WIDTH_PERCENTAGE) / (PointActivity.reportable_types.length + additional_column_attributes.length).to_f
        end
      end

      # The additional columns will be appended at the end of the table.
      def additional_column_attributes
        [user_count_column_attribute]
      end

      def user_count_column_attribute
        { title: "Number of employees", orderable: true }
      end

      def initialize(view_context, engagement_report)
        @engagement_report = engagement_report
        super(view_context, @engagement_report.company)
      end

      def column_table_map
        {}
      end

      def allow_search
        false
      end

      def filtered_records
        _records = all_records
      end

      def paging
        false
      end
    end
  end
end