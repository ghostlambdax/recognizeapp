# frozen_string_literal: true

module Report
  module Engagement
    class CountriesReport < BaseAttributeReport

      def total_user_count_stat_for(country)
        total_user_count_by_countries_query.find { |record| record.country == country }.attributes
      end

      def point_activities_query
        @point_activities_query ||= begin
          select_query_chunks = ["IFNULL(users.country, 'UNASSIGNED') AS 'country'"]

          reportable_point_activity_types.each do |type|
            select_query_chunks << "SUM( CASE WHEN point_activities.activity_type='#{type}' THEN 1 ELSE 0 END ) AS #{type}"
          end

          select_query_chunks << "COUNT( DISTINCT(users.id) ) AS engaged_user_count"

          base_query
            .joins(:user)
            .where("users.status <> 'disabled'")
            .group("users.country")
            .select(select_query_chunks.join(","))
        end
      end

      def total_user_count_by_countries_query
        @total_user_count_by_countries_query ||= begin
          select_query_chunks = [
            "IFNULL(users.country, 'UNASSIGNED') AS 'country'",
            "COUNT( DISTINCT(users.id) ) AS user_count"
          ]

          ::User.where(company_id: company.id).not_disabled.group("users.country").select(select_query_chunks.join(","))
        end
      end

      def user_count_grouped_by_attribute_to_group_by
        total_user_count_by_countries_query.map { |record| Hashie::Mash.new(record.attributes) }
      end

      def attribute_to_group_by
        "country"
      end
    end
  end
end
