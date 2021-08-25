module RedemptionsHelper
  def reward_availability_status(reward, user)
    if !reward_is_redeemable_by_quantity?(reward)
      "unredeemable unredeemable-by-quantity"
    elsif !reward.can_redeem_within_frequency?(user)
      "unredeemable unredeemable-by-frequency"
    elsif !reward.can_redeem_by_points?(user)
      "unredeemable unredeemable-by-points"
    else
      "redeemable"
    end
  end

  def reward_is_redeemable_by_quantity?(reward)
    if reward.has_variants_with_quantity?
      reward.variants.enabled.detect { |variant| reward.can_redeem_within_quantity?(variant) }.present?
    else
      reward.can_redeem_within_quantity?(reward.variants.enabled.first)
    end
  end

  def reward_variant_availability_status(variant, user)
    if !variant.can_redeem_within_quantity?
      "unredeemable-by-quantity"
    elsif !variant.reward.can_redeem_by_points?(user, variant)
      "unredeemable-by-points"
    else
      "redeemable"
    end
  end

  def redemption_points_needed(points, user)
    -(user.redeemable_points - points)
  end

  def options_for_reward_variants(reward, user)
    options = reward.variants.enabled.map do |variant|
      option_data = {}
      option_text = "#{variant.points} #{t("dict.points")} - #{variant.label}"
      option_value = variant.id
      variant_has_quantity = variant.quantity.present?
      if variant_has_quantity
        option_text << " - #{t("reward_variants.quantity_left_html", quantity: variant.quantity_remaining)}"
        option_data[:quantity_remaining] = variant.quantity_remaining
      end
      if show_currency?(user.company)
        number_in_currency = humanized_money_with_symbol(Money.from_amount(variant.face_value, reward.catalog.currency)).no_zeros
        option_data[:price] = number_in_currency
      end
      option_data[:label] = variant.label
      option_data[:variant_availability_status] = reward_variant_availability_status(variant, user)
      option_data[:points] = variant.points
      disabled = (redemption_points_needed(variant.points, user) > 0)

      [option_text, option_value, data: option_data, disabled: disabled]
    end
    options_for_select(options)
  end

  def redemption_status_text(status)
    case status.to_sym
      when :pending
        I18n.t("dict.pending")
      when :approved
        I18n.t("dict.approved")
      when :denied
        I18n.t("dict.denied")
      else
        raise "Unsupported reward status"
    end
  end

  def format_redemption_title(redemption)
    title = redemption.reward.title
    if redemption.reward.provider_reward?
      title += (" " + humanized_money_with_symbol(Money.from_amount(redemption.value_redeemed, redemption.company.currency)))
    end

    return title
  end
end