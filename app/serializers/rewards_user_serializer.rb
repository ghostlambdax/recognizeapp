class RewardsUserSerializer < ActiveModel::Serializer
  include DateTimeHelper

  attributes :user, :redeemable_points, :redeemed_points, :status, :show_points

  def user
    context.link_to(object.full_name, user_path(object)) + " (#{object.email.presence || object.phone})"
  end

  # def redeemed_points
  #   object.redemptions.inject(0){|sum, r| sum + r.point_activities.first.amount.abs}
  # end

  def redeemed_points
    report.redeemed_points
  end

  def redeemable_points
    report.redeemable_points
  end

  def show_points
    context.link_to "Show points", company_admin_point_path(object)
  end

  private

  def report
    from, to = context.params.values_at(:from, :to).map(&:to_i)
    date_range = DateRange.new(from, to)
    Report::User.new(object, date_range.start_time, date_range.end_time)
  end
end
