class PointActivitySerializer < BaseDatatableSerializer
  include DateTimeHelper

  attributes :date, :amount, :activity, :description, :is_redeemable, :user

  def activity_label_map
    @activity_label_map ||= begin
      PointActivity.types.inject({}) do |map, activity|
        map[activity] = I18n.t("point_activities.activity_labels.#{activity}")
        map
      end
    end
  end

  def inverted_activity_label_map
    @inverted_activity_label_map ||= begin
      activity_label_map.invert
    end
  end

  def date
    localize_datetime(object.created_at, :friendly_with_time)
  end

  def activity
    activity_label_map[object.activity_type]
  end

  def is_redeemable
    object.is_redeemable? ? I18n.t("dict.true") : I18n.t("dict.false")
  end

  # Description label / link for point activity object
  def description
    case object.activity_type
    when /^recognition/
      context.link_to object.recognition.slug, recognition_path(object.recognition) if object.recognition.present?
    when /^redemption/
      # FIXME: this causes n+1 query...
      Redemption.includes(:reward).joins(:reward).find(object.activity_object_id).reward_label
    when 'completed_task'
      # FIXME: this causes n+1 query too...
      Tskz::CompletedTask.includes(:task).joins(:task).find(object.activity_object_id).task.name
    end
  end

  def user
    user = object.user
    context.link_to(user.full_name, user_path(user)) + " (#{user.email})"
  end
end
