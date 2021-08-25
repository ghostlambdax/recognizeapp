module Points
  module Calculator
    module UserMethods
      #Point system:
      #10 points per sent recognition
      #100 points per received recognition
      #1 points per sent approval
      #20 points per received approval
      def calculate_total_points
        report = Report::User.new(self, 50.years.ago, Time.current)
        return report.points
      end

      def calculate_interval_points
        report = Report::User.new(self, interval_start_date, Time.current)
        return report.points
      end


      def calculate_redeemable_points
        report = Report::User.new(self, 50.years.ago, Time.current)
        return report.redeemable_points
      end

      def calculate_redeemed_points
        report = Report::User.new(self, 50.years.ago, Time.current)
        return report.redeemed_points
      end
      
      def update_all_points!(update_teams: true)
        teams.map{|t| t.delay(queue: 'points').update_all_points! } if update_teams
        update_total_points!
        update_interval_points!
        update_redeemable_points!
        update_redeemed_points!
      end   

      def update_total_points!
        new_total = calculate_total_points
        update_column(:total_points, new_total) unless self.total_points == new_total
      end

      def update_interval_points!
        new_interval_total = calculate_interval_points
        update_column(:interval_points, new_interval_total) unless self.interval_points == new_interval_total
      end 

      def update_redeemable_points!
        new_redeemable_total = calculate_redeemable_points
        update_column(:redeemable_points, new_redeemable_total) unless self.redeemable_points == new_redeemable_total
      end

      def update_redeemed_points!
        new_redeemed_points_total = calculate_redeemed_points
        update_column(:redeemed_points, new_redeemed_points_total) unless self.redeemed_points == new_redeemed_points_total
      end
    end

  end
end