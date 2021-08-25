# Helpful Example queries:
#   Count of manager -> employees: User.where.not(manager_id: nil).group(:manager_id).having("count_manager_id > 30").count(:manager_id)
#   All managers:  User.where(id: company.users.pluck(:manager_id))
#   Managers with their employees: TODO
module Report
  module Engagement
    # this is an engagement report of a set of a manager's direct reports
    class ManagerReport < Base
      attr_reader :manager

      def initialize(manager, interval, opts={})
        @manager = manager

        # I could design this so that instead of calling super
        # don't inherit off Base, and instead instantiate the Report::Engagement::Users
        # class with the direct reports population
        # But eh, who has time for all those shenanigans...
        super(manager.company, interval, opts)

        # see what i'm doing here? slick, huh...
        @manager_report = Report::User.new(@manager, self.from, self.to)
      end

      def sent_recognitions_count
        @manager_report.sent_recognition_count
      end

      def direct_report_sent_count
        ::Recognition.where(sender_id: user_ids, created_at: from..to).size
      end


      def users
        manager.employees.active.includes(:received_recognitions)
      end

      def top_user_reports
        # User report attribute methods we need to populate for a set of users
        # :sent_recognitions_count, :received_recognitions_count, :badges_most_received, :badges_least_received

        # Potential query methods
        # :bottom_recognition_receivers, :bottom_recognition_senders, :top_recognition_receivers, :top_recognition_senders

        # We ultimately need a sorted set of users along one vector(:badges_most_received desc) while
        # also containing the rest of the data points for each user
        # The problem is that each data point set is retrieved by a (hopefully) separate single query
        # And then you need to merge data sets and sort them.

        # In order to do this, I'm going to maintain a hash: hash[user_id] = UserReportInstance
        # This should give O(4n), where 4 is the number of queries and times we will be adding to the user report instance
        # 

        # 1. start with a sorted set of users by vector (top recognition recipients)
        report_set = self.top_recognition_receivers.inject({}) do |hash, user| 
          hash[user.id] = UserReportDecorator.new(user, received_recognitions_count: user.received_recognitions_count)
          hash
        end

        # 2. Create a new report with just these users
        #    Do next query (sent recognitions count) and add update report set
        new_report = Report::Engagement::UsersReport.new(self.company, users, self.interval)

        # Add the sent recognition count data to everyone in the list
        self.top_recognition_receivers.each do |user| 
          report_set[user.id].sent_recognitions_count = new_report.sent_recognitions_count_for(user)
        end

        # 3. Add badges most and least received
        #    TODO: do this

        # For now, return sorted array, but maybe need to return {hash[id] = UserReportInstance} object
        # so outside clients can sort and/or add other report attributes
        # Note sure about that yet...
        sorted_report_set = report_set.values.sort_by(&:received_recognitions_count).reverse

        return sorted_report_set
      end

      # Same logic as above but for different set of users (n)
      def bottom_user_reports
        report_set = self.bottom_recognition_receivers.inject({}) do |hash, user| 
          hash[user.id] = UserReportDecorator.new(user, received_recognitions_count: user.received_recognitions_count)
          hash
        end

        new_report = Report::Engagement::UsersReport.new(self.company, users, self.interval)
        self.bottom_recognition_receivers.each do |user|
          report_set[user.id].sent_recognitions_count = new_report.sent_recognitions_count_for(user)
        end

        sorted_report_set = report_set.values.sort_by(&:received_recognitions_count)
        return sorted_report_set

      end

      class UserReportDecorator
        attr_reader :user
        attr_accessor :sent_recognitions_count, :received_recognitions_count
        
        def initialize(user, attributes = Hash.new)
          @user = user
          attributes.each do |k,v|
            self.send("#{k}=", v)
          end
          self.sent_recognitions_count ||= 0
          self.received_recognitions_count ||= 0
        end

        # FIXME: This will result in 2n more queries :(
        #        But I'm going to keep truckin on...
        #        To get this data across of a set of users is 
        #        pretty complicated
        def badges_most_received
          user.badge_counts(order: :desc, limit: 3)
        end

        def badges_least_received
          user.badge_counts(order: :asc, limit: 3)
        end
      end
    end
  end
end