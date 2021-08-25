module Report
  module Engagement
    class RolesReport
      attr_reader :company, :from, :to, :opts
      delegate :inspect, :keys, :values, to: :results

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

      def [](key)
        results[key]
      end

      def results
        @results ||= {
          system_roles: SystemRoleResults.results(company, from, to, opts),
          company_roles: CompanyRoleResults.results(company, from, to, opts)
        }
      end

      class RoleResults
        attr_reader :company, :interval, :opts, :results
        attr_reader :shift, :from, :to

        delegate :inspect, :keys, :values, to: :results

        def self.results(company, from, to, opts)
          new(company, from, to, opts)
        end

        def initialize(company, from, to, opts)
          @company = company
          @interval = interval
          @opts = {}
          @from = from
          @to = to
        end

        def base_query
          PointActivity
            .where(company_id: company.id)
            .where(created_at: from..to)
        end

        def [](key)
          results[key]
        end

        def results
          raise "Must be implemented by subclass"
        end

      end

      class RoleResult < ResultBase
        alias_method :role, :report_by
        delegate :long_name, to: :role

        def user_count
          results["user_count"]
        end
      end

      class SystemRoleResults < RoleResults

        def query
          base_query
            .joins({user: :user_roles})
            .group(["user_roles.role_id", "point_activities.activity_type"])
        end

        def results
          @results ||= {
            Role.company_admin.id => role_results(Role.company_admin),
            Role.manager.id => role_results(Role.manager)
          }
        end

        def role_results(role)
          data = query.where(user_roles: {role_id: role.id})
                   .count
                   .inject({}){|hash, (key,count)|
                     role_id, activity_type = key[0], key[1]
                     hash[activity_type] = count
                     hash
                   }
          data["user_count"] = @company.get_user_ids_by_role_id(role.id, include_disabled: false).size
          RoleResult.new(role, data)
        end

      end

      class CompanyRoleResults < RoleResults

        def results
          @results ||= begin
            base_query
              .joins({user: :user_company_roles})
              .group(["user_company_roles.company_role_id", "point_activities.activity_type"])
              .count
              .inject({}){|hash, (key,count)|
                role_id, activity_type = key[0], key[1]
                hash[role_id] ||= RoleResult.new(@company.company_roles.detect{|r| r.id == role_id})
                hash[role_id].send("#{activity_type}=",count)
                hash[role_id].results["user_count"] ||= @company.get_user_ids_by_company_role_id(role_id, include_disabled: false).size
                hash
              }
          end
          @results
        end

      end
    end
  end
end
