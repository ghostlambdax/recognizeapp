class RewardsRedemptionsSerializer < BaseDatatableSerializer
  include UsersUrlConcern

  attributes :employee_id, :email, :first_name, :last_name, :full_name, :date, :catalog, :reward_label, :reward, :points, :value, :reward_type, :status, :actions
  delegate :employee_id, :email, :first_name, :last_name, to: :redeemer

  def date
    context.localize_datetime(object.created_at, :friendly_with_time)
  end

  def catalog
    object.reward.catalog.currency
  end

  def reward_label
    object.reward_variant.label
  end

  def redeemer
    object.user
  end

  def reward
    # value_redeemed = object.reward.provider_reward? ? "- #{value}" : ""
    # "#{object.reward.title} #{value_redeemed}"
    
    # The redemptions table shows the value in the native currency, so we just need the title
    object.reward.title
  end

  def full_name
    context.link_to redeemer.full_name, user_path(redeemer)
  end

  def reward_type
    object.reward.reward_type
  end

  def points
    object.points_redeemed.to_i
  end

  def value
    context
        .humanized_money_with_symbol(Money.from_amount(object.value_redeemed, object.reward.catalog.currency))
        .no_zeros
  end

  def status
    context.redemption_status_text object.status
  end

  # Caution: This column is rendered as-is without escaping.
  def actions
    html_str = ''
    if object.status.to_sym == :pending
      html_str << "#{context.approve_redemption_button(object)}"
      html_str << "#{context.deny_redemption_button(object)}"
    elsif object.status.to_sym != :denied
      if object.reward.provider_reward?
        html_str << "#{context.redemption_view_details_link(object)}"
      else
        if object.additional_instructions.present?
          html_str << "<div>#{context.redemption_view_additional_instructions_link(object)}</div>"
        end
      end
    end
    html_str
  end

  # attributes to skip html escaping (used by parent class)
  def html_safe_attributes
    [:actions]
  end
end
