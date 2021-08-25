# Report::Engagement::Base purpose is to give leaderboards
# across a population of users. The leaderboards will contain engagement stats 
# (Sent, received recognitions, etc) on that population
module Report
  module Engagement
    class Base
      attr_reader :company, :interval, :shift, :from, :to, :sort_direction, :opts

      def initialize(company, interval=Interval.new(company.reset_interval), opts={})
        @company = company
        @interval = interval
        @opts = opts
        @shift = (opts[:shift] ||= -1) # default to the previous interval
        @from = interval.start(opts.slice(:shift, :time))
        @to = interval.end(opts.slice(:shift, :time))
      end

      def all_recognitions
        company.recognitions.where(created_at: from..to)
      end

      def total_num_recognitions
        all_recognitions.size
      end

      def user_ids
        # use pluck if the AR query hasn't been loaded yet (way quicker)
        # if we have an array or an already loaded query, just :map it to avoid an additional query
        @user_ids ||= ((users.respond_to?(:loaded?) && !users.loaded?) ? users.pluck(:id) : users.map(&:id)).uniq
      end

      def users
        raise "must implemented by subclass"
      end

      # TODO: this methods could probably be moved to like a Report::Engagement::GroupConcern
      #       as they are report methods that apply to a group of users
      def bottom_recognition_receivers
        @bottom_recognition_receivers ||= begin
          data = leaderboard_by_received_recognitions
          values = data.map(&:received_recognitions_count).uniq
          data.select{|u| u.received_recognitions_count < threshold(values)}
        end
      end

      def bottom_recognition_senders
        @bottom_recognition_senders ||= begin
          data = leaderboard_by_sent_recognitions
          values = data.map(&:sent_recognitions_count).uniq
          data.select{|u| u.sent_recognitions_count < threshold(values)}.reverse
        end
      end

      def leaderboard_by_received_recognitions
        @leaderboard_by_recevied_recognitions ||= begin
          set = leaders_by_received_recognitions(order: :desc)
          found_ids = set.map(&:id)
          missings_ids = user_ids - found_ids
          users_with_zero = ::User.active.where(id: missings_ids).each{|u| u.received_recognitions_count = 0}
          set += users_with_zero
          set
        end
      end

      def leaderboard_by_sent_recognitions
        @leaderboard_by_sent_recognitions ||= begin
          set = leaders_by_sent_recognitions(order: :desc)
          found_ids = set.map(&:id)
          missings_ids = user_ids - found_ids
          users_with_zero = ::User.active.where(id: missings_ids).each{|u| u.sent_recognitions_count = 0}
          set += users_with_zero
          set
        end
      end

      def group_sent_recognition_count
        @group_sent_recognition_count ||= Recognition.where(
          sender_company_id: company.id, 
          sender_id: user_ids, 
          created_at: from..to).size
      end

      def group_received_recognition_count
        @group_received_recognition_count ||= PointActivity.where(
          company_id: company.id, 
          activity_type: PointActivity::Type.recognition_recipient,
          user_id: user_ids, 
          created_at: from..to).size
      end

      def sent_recognitions_count_for(user)
        # FIXME: might want to refactor this
        #        so we don't get O(n^2)
        #        can get O(n) + O(1) if we cached an id=>user map
        #        and just need lookup on userid
        leaderboard_by_sent_recognitions.detect{|u| u.id == user.id}.sent_recognitions_count
      end

      def top_recognition_receivers
        @top_recognition_receivers ||= begin
          data = leaderboard_by_received_recognitions
          values = data.map(&:received_recognitions_count).uniq
          data.select{|u| u.received_recognitions_count >= threshold(values)}
        end
      end

      def top_recognition_senders
        @top_recognition_senders ||= begin
          data = leaderboard_by_sent_recognitions
          values = data.map(&:sent_recognitions_count).uniq
          data.select{|u| u.sent_recognitions_count >= threshold(values)}
        end
      end

      def users_with_received_recognitions_count
        # .size returns map of grouped user counts of recognitions
        # just need to count the users (ie keys)
        @users_with_received_recognitions_count ||= leaders_by_received_recognitions.size.keys.length
      end

      def users_with_sent_recognitions_count
        # .size returns map of grouped user counts of recognitions
        # just need to count the users (ie keys)
        @users_with_sent_recognitions_count ||= leaders_by_sent_recognitions.size.keys.length
      end

      def has_data?

        # This is a method to let clients know if there is any data in the report whatsoever
        # This is useful to determine, for example, whether you want to email a particular user their report
        # Or to simply show a "No data" response.
        #
        # TODO: allow clients to dynamically declare what bits of data
        #       they want, maybe its a proc that's passed in for this method?
        #       This allows clients to cherry pick the data they want
        #       so we don't slow down the works loading data we don't need

        has_sent_recognition_data? || has_received_recognition_data?
      end

      # Note on Filtering: need to check if sent / received recognitions are actually present,
      #                    because the leaderboards add back users_with_zero corresponding activities
      def has_sent_recognition_data?
        [top_recognition_senders, bottom_recognition_senders].flatten.any? { |u| u.sent_recognitions_count > 0 }
      end

      def has_received_recognition_data?
        [top_recognition_receivers, bottom_recognition_receivers].flatten.any? { |u| u.received_recognitions_count > 0 }
      end

      private

      def leaders_by_received_recognitions(order: 'DESC', exclude_ids: nil, limit: nil)
        order = %i(asc desc).include?(order) ? order.upcase : 'DESC'

        match_ids = user_ids - (exclude_ids || [])
        result = ::User.active
                .joins(:point_activities)
                .where(company_id: company.id)
                .where(id: match_ids)
                .where(point_activities: {created_at: from..to, activity_type: PointActivity::Type.recognition_recipient})

        # if exclude_ids.present?
        #   result.where.not(id: exclude_ids)
        # end

        result = result
                .select("users.*, COUNT(point_activities.recognition_id) as received_recognitions_count")
                .group("users.id")
                .order("received_recognitions_count #{order}, users.first_name ASC, users.last_name ASC")

        if limit.present?
          result = result.limit(limit)
        end

        return result
      end

      def leaders_by_sent_recognitions(order: 'DESC', exclude_ids: nil, limit: nil)
        order = %i(asc desc).include?(order) ? order.upcase : 'DESC'
        match_ids = user_ids - (exclude_ids || [])

        result = ::User.active
          .joins(:sent_recognitions)
          .where(recognitions: {sender_company_id: company.id})
          .where(recognitions: {sender_id: match_ids})
          .where.not(id: ::User.system_user.id)
          .where(recognitions: {created_at: from..to})

        # if exclude_ids
        #   result.where.not(id: exclude_ids)
        # end

        result = result
          .select("users.*, COUNT(recognitions.id) AS sent_recognitions_count")
          .group("users.id")
          .reorder('')
          .order("sent_recognitions_count #{order}, users.first_name ASC, users.last_name ASC")

        if limit.present?
          result = result.limit(limit)
        end

        return result
      end

      def threshold(array)
        sorted = array.uniq.sort
        len = sorted.length
        (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0        
      end
    end
  end
end