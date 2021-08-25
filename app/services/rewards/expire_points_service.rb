# This class intends to replace Rewards::PointsResetter by adding new PointActivity with
# 'point_expiration' point_activity type and amount equal to negative of user's redeemable_points.
# Main goal of the service is to make user's redeemable_points equals to zero, so that those points
# are not available for redeem.
#
# Usage examples:
# - expire company's points
#   - without background job
#       `Rewards::ExpirePointsService.expire_company company_or_id`
#   - with background job
#       `Rewards::ExpirePointsService.run_at(date: 2.days.from_now, hour: 2, minute: 0).expire_company company_or_id`
# - expire user's points
#   - without background job
#       `Rewards::ExpirePointsService.expire_user user_or_id`
#   - with background job
#       `Rewards::ExpirePointsService.run_at(date: Date.current, hour: 23, minute: 30).expire_user user_or_id`
#
# NOTE: These service functions will return reports after resetting the points.
class Rewards::ExpirePointsService
  attr_reader :date, :hour, :minute, :run_with_delay

  def initialize(date = Date.current, hour = Time.current.hour, minute = Time.current.min, run_with_delay = false)
    @date = date
    @hour = hour
    @minute = minute
    @run_with_delay = run_with_delay
  end

  def self.run_at(date: Date.current, hour: 0, minute: 0)
    self.new(date, hour, minute, true)
  end

  def expire_company(company_or_id)
    company = find_company(company_or_id)
    if delay?
      Time.use_zone(company.settings.timezone) do
        self.delay(run_at: when_to_run.in_time_zone, queue: 'priority_caching').run_for_company(company.id)
      end
    else
      self.run_for_company(company.id)
    end
  end

  def self.expire_company(company_or_id)
    self.new.expire_company(company_or_id)
  end

  def expire_user(user_or_id)
    user = find_user(user_or_id)
    if delay?
      Time.use_zone(user.company_timezone) do
        self.delay(run_at: when_to_run.in_time_zone, queue: 'priority_caching').run_for_user(user.id)
      end
    else
      self.run_for_user(user.id)
    end
  end

  def self.expire_user(user_or_id)
    self.new.expire_user(user_or_id)
  end

  def run_for_company(company_or_id)
    company = find_company(company_or_id)
    report = PointsReportService.new
    company.users.with_deleted.find_each do |user|
      report << self.run_for_user(user, readable_report: false)
    end
    readable_report = report.generate_readable_report
    Rails.logger.info readable_report.inspect if delay?
    readable_report
  end

  def run_for_user(user_or_id, readable_report: true)
    user = find_user(user_or_id)
    begin
      user_points_expire_service = UserPointsService.new(user)
      user_points_expire_service.expire
      report = user_points_expire_service.report
    rescue Exception => e
      Rails.logger.error("Rewards::ExpirePointsService.expire_user failed for user:- #{user.id}")
      Rails.logger.error(e.message)
      report = {
        user_id: user.id,
        full_name: user.full_name,
        errors: [e.message]
      }
      ExceptionNotifier.notify_exception(e, { data: { **report } })
    end

    final_report = if readable_report
               PointsReportService.new([report]).generate_readable_report
             else
               report
             end
    Rails.logger.info final_report.inspect if delay?
    final_report
  end

  private
  def delay?
    @run_with_delay == true
  end

  def when_to_run
    Time.current.change(year: date.year, month: date.month, day: date.day, hour: hour, min: minute)
  end

  def find_company(company_or_id)
    company_or_id.is_a?(Company) ? company_or_id : Company.find(company_or_id)
  end

  def find_user(user_or_id)
    user_or_id.is_a?(User) ? user_or_id : User.find(user_or_id)
  end

  class UserPointsService
    attr_accessor :user, :activity

    def initialize(user)
      @user = user
    end

    def expire
      Rails.logger.info("Expiring points for user #{user.full_name}.")
      create_point_activity_expiration
      update_points
    end

    def report
      opts = { user_id: user.id, full_name: user.full_name }
      other_opts = if activity
                     activity.errors.any? ? { errors: activity.errors.full_messages } : { success: true, point_activity_id: activity.id }
                   else
                     { remarks: 'Redeemable points is 0', skipped: true }
                   end
      opts.merge(other_opts)
    end

    private
    def create_point_activity_expiration
      return if user.redeemable_points == 0

      @activity = user.point_activities.build.tap do |p|
        p.amount = -user.redeemable_points
        p.activity_type = 'point_expiration'
        p.company_id = user.company_id
        p.network = user.network
        p.activity_object_type = 'User'
        p.activity_object_id = user.id
        p.is_redeemable = true
      end
      @activity.save
    end

    def update_points
      user.delay(queue: 'points').update_all_points!
    end
  end

  class PointsReportService < Array
    def generate_readable_report
      report = { success: [], errors: [], skipped: [] }
      self.each do |result|
        if result[:skipped]
          report[:skipped].push(result)
        elsif result[:success]
          report[:success].push(result)
        else
          report[:errors].push(result)
        end
      end
      return report
    end
  end
end
