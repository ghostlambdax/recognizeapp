module Report
  module Engagement
    class TeamsReport < BaseAttributeReport

      def total_user_count_stat_for(team)
        total_user_count_by_teams.find { |record| record.team == team }
      end

      def point_activities_query
        @point_activities_query ||= begin
          select_query_chunks = ["teams.name AS team"]

          reportable_point_activity_types.each do |type|
            select_query_chunks << "SUM( CASE WHEN point_activities.activity_type='#{type}' THEN 1 ELSE 0 END ) AS #{type}"
          end

          select_query_chunks << "COUNT( DISTINCT(users.id) ) AS engaged_user_count"

          base_query
            .joins({user: :teams})
            .where("users.status <> 'disabled'")
            .group("user_teams.team_id")
            .select(select_query_chunks.join(","))
        end
      end

      def total_user_count_by_teams
        teams_with_users = teams_with_users_query.map { |record| Hashie::Mash.new(record.attributes) }
        teams_without_users = teams_without_users_query.map { |record| Hashie::Mash.new(record.attributes) }
        teams_with_users + teams_without_users
      end

      def teams_with_users_query
        @teams_with_users_query ||= begin
          select_query_chunks = [
            "IFNULL(teams.name, 'UNASSIGNED') AS team",
            "COUNT( DISTINCT(users.id) ) AS user_count"
          ]

          ::User.where(company_id: company.id).not_disabled
            .left_outer_joins(:teams)
            .group(:team).select(select_query_chunks.join(","))
        end
      end

      def teams_without_users_query
        @teams_without_users_query ||= begin
          select_query_chunks = [
            "teams.name AS team",
            "0 AS user_count"
          ]

          ::Team.where(company_id: company.id)
            .left_outer_joins(:users)
            .group(:team)
            .having("count(if(users.status <> 'disabled', users.id, NULL))=0")
            .select(select_query_chunks.join(","))
        end
      end

      def user_count_grouped_by_attribute_to_group_by
        total_user_count_by_teams
      end

      def attribute_to_group_by
        "team"
      end

    end
  end
end
