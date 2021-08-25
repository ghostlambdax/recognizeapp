module CompaniesHelper
  def options_for_reset_interval(company)
    options = Company
      .reset_intervals
      .map { |key, value| [value.to_s.humanize, key]}
    options_for_select(options, company.reset_interval)
  end

  def options_for_global_nomination_award_limit(company)
    options_for_nomination_award_limit(company.nomination_global_award_limit_interval_id.to_s)
  end

  def options_for_badge_nomination_award_limit(badge)
    options_for_nomination_award_limit(badge.nomination_award_limit_interval_id.to_s)
  end  

  def options_for_nomination_award_limit(selected_value)
    intervals_with_trimester = ordered_intervals(Interval::RESET_INTERVALS_WITH_TRIMESTER_AND_NULL)
    intervals_with_trimester = intervals_with_trimester.reject{ |k, _|
      [Interval::DAILY, Interval::WEEKLY].include?(k)
    }
    options = intervals_with_trimester.map { |key, _|
      # 'once a month', I18n style
      interval = Interval.new(key)
      label = interval.null? ? 
        'No limit' : 
        I18n.t('nominations.often', count: 1, what: reset_interval_noun(interval))
      [label.humanize, key]
    }
    options_for_select(options, selected_value)
  end

  def company_admin_custom_badges_link(name, **opts)
    link_to name, company_path(anchor: 'custom_badges', **opts), data: { turbolinks: false }
  end
end
