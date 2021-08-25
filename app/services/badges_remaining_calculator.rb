class BadgesRemainingCalculator
  include IntervalHelper

  attr_reader :user, :company, :prospective_recipients

  def self.recognition_badges_remaining(user)
    new(user).recognition_badges_remaining
  end

  def self.nomination_badges_remaining(user)
    new(user).nomination_badges_remaining
  end

  def initialize(user)
    @user = user
    @company = user.company
    @prospective_recipients = 0 # future feature maybe to allow recalculating based on potential new recipients
  end

  def recognition_badge_global_limit
    return nil unless company.recognition_limit_frequency.present? && company.recognition_limit_interval.present?

    quantity = if company.recognition_limit_scope.recognition?
      start_time = company.recognition_limit_interval.start
      interval_sent_recognitions_count = user.sent_recognitions.not_denied.where("created_at >= ?", start_time).size
      company.recognition_limit_frequency - interval_sent_recognitions_count

    else
      start_time = company.recognition_limit_interval.start
      interval_sent_users_count = user.sent_recognitions.not_denied.where("created_at >= ?", start_time).map(&:user_recipients).flatten.size
      company.recognition_limit_frequency - (interval_sent_users_count + prospective_recipients)

    end

    return BadgeLimit.new(:global, quantity, company.recognition_limit_interval)
  end

  def recognition_badge_default_limit
    return nil unless company.default_recognition_limit_interval.present? && company.default_recognition_limit_frequency.present?

    quantity = if company.recognition_limit_scope.recognition?
      start_time = company.default_recognition_limit_interval.start
      interval_sent_recognitions_count = user.sent_recognitions.not_denied.where("created_at >= ?", start_time).size
      company.default_recognition_limit_frequency - interval_sent_recognitions_count

    else
      start_time = company.default_recognition_limit_interval.start
      interval_sent_users_count = user.sent_recognitions.not_denied.where("created_at >= ?", start_time).map(&:user_recipients).flatten.size
      company.default_recognition_limit_frequency - (interval_sent_users_count + prospective_recipients)

    end    

    return BadgeLimit.new(:default, quantity, company.default_recognition_limit_interval)
  end

  def sendable_recognition_badges
    user.sendable_badges.select{|b| b.recognition? }
  end

  def recognition_badges_remaining
    sendable_recognition_badges.inject({}) do |map, badge|
      # quantities = [recognition_badge_global_limit, (recognition_badge_quantity(badge) || recognition_badge_default_limit)]
      # quantity = quantities.reject(&:blank?).min

      quantity, interval = recognition_badge_quantity_with_interval(badge)

      if interval
        quantity_with_interval_text = I18n.t('badges.badges_remaining_html', quantity: quantity, interval_with_article: reset_interval_noun_with_current_article(interval))
      else
        quantity_with_interval_text = ""
      end

      map[badge.id] = {badge: badge, quantity: quantity, interval: interval, quantity_with_interval_text: quantity_with_interval_text }
      map
    end
  end

  def recognition_badge_quantity(badge)
    return nil unless badge.sending_frequency.present? && badge.sending_interval.present?

    quantity = if company.recognition_limit_scope.recognition?
      start_time = badge.sending_interval.start
      interval_sent_recognitions_count = user.sent_recognitions.not_denied.where("created_at >= ?", start_time).where(badge_id: badge.id).size
      badge.sending_frequency - interval_sent_recognitions_count
    else
      start_time = badge.sending_interval.start
      interval_sent_users_count = user.sent_recognitions.not_denied.where("created_at >= ?", start_time).where(badge_id: badge.id).map(&:user_recipients).flatten.size
      badge.sending_frequency - (interval_sent_users_count + prospective_recipients)
    end

    return BadgeLimit.new(:badge, quantity, badge.sending_interval)
  end

  def recognition_badge_quantity_with_interval(badge)
    global_limit = recognition_badge_global_limit
    badge_limit = recognition_badge_quantity(badge)
    default_limit = recognition_badge_default_limit

    # need to pick lowest of [global, (badge || default)]
    # first, determine badge or default to determine min against global
    badge_or_default_limit = badge_limit || default_limit

    if global_limit && (global_limit < badge_or_default_limit)
      [global_limit.quantity, global_limit.interval]
    elsif badge_or_default_limit
      [badge_or_default_limit.quantity, badge_or_default_limit.interval]
    else
      nil
    end

  end

  def nomination_badges_remaining
  end

  private

  class BadgeLimit
    attr_reader :type, :quantity, :interval

    def initialize(type, quantity, interval)
      @type = type
      @quantity = quantity
      @interval = interval
    end

    def <(other)
      return self unless other.present?
      self.normalized_value < other.normalized_value
    end

    # normalize to greatest interval unit which is year
    def normalized_value
      factor = Interval.conversion_factor(Interval.yearly, self.interval)
      quantity * factor
    end
  end
end