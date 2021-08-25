class BadgeSerializer < ActiveModel::Serializer
  include DateTimeHelper
  include IntervalHelper

  attributes :id, :short_name, :description, :points, :is_instant, :is_achievement,
             :achievement_frequency, :achievement_interval, :sending_frequency,
             :sending_interval, :is_nomination, :is_anniversary, :nomination_award_limit_interval,
             :is_quick_nomination, :show_in_badge_list, :allow_self_nomination, :roles_with_permission, :sort_order

  def achievement_interval
    object.achievement_interval_id.present? ?
      reset_interval_adverb(Interval.new(object.achievement_interval_id)) :
      nil
  end

  def sending_interval
    object.sending_interval_id.present? ?
      reset_interval_adverb(Interval.new(object.sending_interval_id)) :
      nil
  end

  def nomination_award_limit_interval
    object.nomination_award_limit_interval_id.present? ?
      reset_interval_adverb(Interval.new(object.nomination_award_limit_interval_id)) :
      nil
  end

  def roles_with_permission
    object.roles_with_permission(:send).present? ?
      object.roles_with_permission(:send).map{|r| "#{r.name}"} :
      nil
  end

end
