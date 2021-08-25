module BadgesHelper
  def selected_badge_roles(badge)
    badge.roles_with_permission(:send).map(&:id)
  end

  def sort_badges(badges)
    # Do a case insensitive sort; similar to AR `order`.
    # Note: ^^ Sort based on the sort_order otherwise fall back to short_name
    badges.sort_by { |b| [b.sort_order, b.short_name] }
  end

  def show_badge_points?(badge)
    return false if badge.is_nomination
    return false if badge.requires_approval && badge.point_values.empty?

    true
  end

  def formatted_badge_points(badge, with_label: true)
    points = if badge.requires_approval?
               approval_badge_points(badge)
             else
               badge.points
             end

    points = I18n.t('dict.pts', points: points) if points && with_label

    points
  end

  def approval_badge_points(badge)
    point_values = badge.point_values
    return nil if point_values.empty?

    if point_values.size > 1
      "#{point_values.min}-#{point_values.max}"
    else
      point_values.first.to_s
    end
  end

  def options_for_point_variants(badge)
    selected = badge.requires_approval? ? badge.point_values : badge.points
    container = badge.point_values.dup
    container << badge.points unless container.include?(badge.points)
    options_for_select(container, selected)
  end

  def default_value_for_points(badge)
    badge.requires_approval? ? badge.point_values[0] : badge.points
  end
end
