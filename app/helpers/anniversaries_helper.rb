module AnniversariesHelper
  def default_anniversary_badge_image(badge)
    template = ANNIVERSARY_BADGES[badge.anniversary_template_id]
    path = "badges/anniversary/#{template.image}"
    return path
  end

  def anniversary_tertiary_nav_link(label, path, matching_paths, opts = {})
    content_tag(:li, class: ('active' if active_subnav?(matching_paths))) do
      link_to label, path, class: opts[:class]
    end
  end
end